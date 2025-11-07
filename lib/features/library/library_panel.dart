import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/ui_settings.dart';

class LibraryPanel extends StatefulWidget {
  const LibraryPanel({super.key});

  @override
  State<LibraryPanel> createState() => _LibraryPanelState();
}

class _LibraryPanelState extends State<LibraryPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _sortMode = 'name'; // name | date

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _autoScrollToCurrent();
  }

  Future<void> _autoScrollToCurrent() async {
    final audio = context.read<AudioService>();
    if (!_scrollController.hasClients) return;
    if (audio.currentIndex < 0) return;
    await Future.delayed(const Duration(milliseconds: 150));
    final itemOffset = audio.currentIndex * 56.0;
    _scrollController.animateTo(
      itemOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickFolderAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null) {
        setState(() => _isLoading = false);
        return;
      }
      final dir = Directory(dirPath);
      final all = <FileSystemEntity>[];
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final lower = entity.path.toLowerCase();
          if (lower.endsWith('.mp3') ||
              lower.endsWith('.wav') ||
              lower.endsWith('.m4a') ||
              lower.endsWith('.flac')) {
            all.add(entity);
          }
        }
      }
      if (!mounted) return;
      context.read<AudioService>().setLibraryFiles(all);
      _autoScrollToCurrent();
    } catch (e) {
      debugPrint('Library load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FileSystemEntity> _applyFilters(
      List<FileSystemEntity> source, UiSettings ui) {
    var list = List<FileSystemEntity>.from(source);
    final query = ui.libraryQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((f) {
        final name =
            f.path.split(Platform.pathSeparator).last.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    if (_sortMode == 'name') {
      list.sort((a, b) {
        final an = a.path.split(Platform.pathSeparator).last.toLowerCase();
        final bn = b.path.split(Platform.pathSeparator).last.toLowerCase();
        return an.compareTo(bn);
      });
    } else {
      list.sort((a, b) {
        final at = (a.statSync().modified).millisecondsSinceEpoch;
        final bt = (b.statSync().modified).millisecondsSinceEpoch;
        return bt.compareTo(at);
      });
    }

    return list;
  }

  void _showContextMenu(
      BuildContext context,
      Offset position,
      FileSystemEntity file,
      int index,
      ) async {
    final audio = context.read<AudioService>();
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        const PopupMenuItem(
          value: 'play',
          child: Text('Play'),
        ),
        const PopupMenuItem(
          value: 'play_next',
          child: Text('Play next'),
        ),
        const PopupMenuItem(
          value: 'reveal',
          child: Text('Open in folder'),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Text('Remove from library'),
        ),
      ],
    );

    switch (selected) {
      case 'play':
        final name = file.path.split(Platform.pathSeparator).last;
        audio.playFromLibrary(name, file.path, index);
        break;
      case 'remove':
        final list = List<FileSystemEntity>.from(audio.libraryFiles);
        list.remove(file);
        audio.setLibraryFiles(list);
        break;
      case 'reveal':
        // just debug print; desktop-specific opening can be added later
        debugPrint('Open in folder: ${file.path}');
        break;
      case 'play_next':
        // todo: queue logic
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final ui = context.watch<UiSettings>();
    final files = _applyFilters(audio.libraryFiles, ui);

    return Container(
      color: const Color(0xFF0F1014),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
              children: [
                const Text(
                  'Library',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Add folder',
                  onPressed: _isLoading ? null : _pickFolderAndLoad,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  onSelected: (v) {
                    setState(() => _sortMode = v);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by name'),
                    ),
                    PopupMenuItem(
                      value: 'date',
                      child: Text('Sort by date'),
                    ),
                  ],
                  icon: const Icon(Icons.sort),
                ),
              ],
            ),
          ),
          // SUB HEADER
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Local files',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          // LIST
          Expanded(
            child: files.isEmpty
                ? const Center(
                    child: Text(
                      'No audio files.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final name =
                          file.path.split(Platform.pathSeparator).last;
                      final isCurrent = audio.currentTitle == name;
                      final glow = ui.glowEffects;

                      return GestureDetector(
                        onSecondaryTapDown: (details) =>
                            _showContextMenu(context, details.globalPosition,
                                file, index),
                        onDoubleTap: () {
                          audio.playFromLibrary(name, file.path, index);
                          _autoScrollToCurrent();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF7B5CFF).withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: glow && isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF7B5CFF)
                                          .withOpacity(0.35),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: ListTile(
                            dense: true,
                            leading: _buildThumb(name, isCurrent),
                            title: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              file.path,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white24),
                            ),
                            trailing: isCurrent
                                ? const Icon(Icons.equalizer,
                                    size: 16, color: Colors.greenAccent)
                                : null,
                            onTap: () {
                              audio.playFromLibrary(
                                  name, file.path, index);
                              _autoScrollToCurrent();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(String name, bool active) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        gradient: active
            ? const LinearGradient(
                colors: [
                  Color(0xFF7B5CFF),
                  Color(0xFF9A7BFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF1D1F27),
                  Color(0xFF151721),
                ],
              ),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
