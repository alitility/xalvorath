import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/audio_service.dart';

class LibraryPanel extends StatelessWidget {
  const LibraryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final files = audio.libraryFiles;

    return Container(
      color: const Color(0xFF0F1014),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Library',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: files.isEmpty
                ? const Center(
                    child: Text(
                      'No audio files.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final name =
                          file.path.split(Platform.pathSeparator).last;
                      final isCurrent = audio.currentTitle == name;
                      return ListTile(
                        dense: true,
                        selected: isCurrent,
                        selectedTileColor: const Color(0x22FFFFFF),
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B5CFF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.music_note, size: 16),
                        ),
                        title: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text(
                          'Local file',
                          style: TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          final originalIndex =
                              audio.libraryFiles.indexOf(file);
                          audio.playFromLibrary(name, file.path, originalIndex);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
