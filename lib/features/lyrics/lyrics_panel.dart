import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../core/services/audio_service.dart';
import '../../core/services/ui_settings.dart';

class LyricsPanel extends StatefulWidget {
  const LyricsPanel({super.key});

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  int _activeTab = 0; // 0: lyrics, 1: info, 2: queue

  String? _lastTrackKey;

  bool _lyricsLoading = false;
  String? _lyricsText;
  String? _lyricsError;

  bool _infoLoading = false;
  Map<String, dynamic>? _trackInfo;
  String? _infoError;

  final _lyricsScroll = ScrollController();

  @override
  void dispose() {
    _lyricsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final ui = context.watch<UiSettings>();

    final currentTitle = audio.currentTitle;
    final currentKey = currentTitle ?? '—';
    if (currentTitle != null && currentKey != _lastTrackKey) {
      _lastTrackKey = currentKey;
      if (_activeTab == 0) {
        _fetchLyricsFor(currentTitle);
      } else if (_activeTab == 1) {
        _fetchInfoFor(currentTitle);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1014),
        border: Border(
          left: BorderSide(color: Color(0xFF0F1014), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(audio),
          _buildTabs(ui),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildContent(audio),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AudioService audio) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Right Panel',
            style: TextStyle(fontSize: 13, color: Colors.white30),
          ),
          const SizedBox(height: 2),
          Text(
            audio.currentTitle ?? 'No track selected',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(UiSettings ui) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _tabButton('Lyrics', 0, ui),
          const SizedBox(width: 6),
          _tabButton('Info', 1, ui),
          const SizedBox(width: 6),
          _tabButton('Queue', 2, ui),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, UiSettings ui) {
    final selected = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
        final audio = context.read<AudioService>();
        final title = audio.currentTitle;
        if (title != null) {
          if (index == 0 && _lyricsText == null && !_lyricsLoading) {
            _fetchLyricsFor(title);
          } else if (index == 1 && _trackInfo == null && !_infoLoading) {
            _fetchInfoFor(title);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ui.accentColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? ui.accentColor.withOpacity(0.6)
                : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.white54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AudioService audio) {
    switch (_activeTab) {
      case 0:
        return _lyricsView(audio);
      case 1:
        return _infoView(audio);
      case 2:
        return _queueView(audio);
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------------------------------------
  // LYRICS VIEW (animated, timed)
  // -------------------------------------------------
  Widget _lyricsView(AudioService audio) {
    if (_lyricsLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_lyricsError != null) {
      return Center(
        child: Text(
          _lyricsError!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      );
    }
    if (_lyricsText == null) {
      return const Center(
        child: Text(
          'No lyrics available for this track.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    final ui = context.watch<UiSettings>();
    final lines = _lyricsText!.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final dur = audio.duration;
    final pos = audio.position;

    // tahmini zamanlama: her satır eşit süre
    // örn: 180 sn / 30 satır = 6 sn/satır
    final totalMs = dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds;
    final perLine = (totalMs / (lines.isEmpty ? 1 : lines.length)).floor();

    // şu an hangi satır çalıyor?
    final currentLine = (pos.inMilliseconds / perLine).floor().clamp(0, (lines.length - 1).clamp(0, 99999));

    // aktif satıra otomatik kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lyricsScroll.hasClients) {
        final target = currentLine * 34.0; // her satırın yaklaşık yüksekliği
        _lyricsScroll.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Padding(
      key: const ValueKey('lyrics'),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: ListView.builder(
        controller: _lyricsScroll,
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final isActive = index == currentLine;
final bool isDemon = (ui as dynamic).demonMode == true;
final baseColor = isDemon ? const Color(0xFFFF6B6B) : ui.accentColor;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isActive ? 1.0 : 0.35,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: isActive ? 14 : 12,
                height: 1.35,
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                shadows: isActive && ui.glowEffects
                    ? [
                        Shadow(
                          color: baseColor.withOpacity(0.6),
                          blurRadius: 12,
                        )
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Text(lines[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------
  // INFO VIEW (same as before)
  // -------------------------------------------------
  Widget _infoView(AudioService audio) {
    return Container(
      key: const ValueKey('info'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: _infoLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _infoError != null
              ? Text(
                  _infoError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                )
              : _trackInfo != null
                  ? ListView(
                      children: [
                        const Text('Track info',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _infoRow('Title', _trackInfo!['trackName'] ?? audio.currentTitle ?? '—'),
                        _infoRow('Artist', _trackInfo!['artistName'] ?? '—'),
                        _infoRow('Album', _trackInfo!['collectionName'] ?? '—'),
                        _infoRow('Genre', _trackInfo!['primaryGenreName'] ?? '—'),
                        _infoRow('Source', 'Online lookup'),
                        const SizedBox(height: 12),
                        if (_trackInfo!['artworkUrl100'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_trackInfo!['artworkUrl100']),
                          ),
                      ],
                    )
                  : const Text(
                      'No info for this track.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------
  // QUEUE VIEW (same as before)
  // -------------------------------------------------
  Widget _queueView(AudioService audio) {
    return Container(
      key: const ValueKey('queue'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ListView.builder(
        itemCount: audio.libraryFiles.length,
        itemBuilder: (context, index) {
          final f = audio.libraryFiles[index];
          final name = f.path.split(Platform.pathSeparator).last;
          final isCurrent = index == audio.currentIndex;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.white10 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                isCurrent ? Icons.play_arrow : Icons.music_note,
                size: 18,
                color: isCurrent ? Colors.greenAccent : Colors.white60,
              ),
              title: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? Colors.white : Colors.white70,
                ),
              ),
              onTap: () {
                audio.playFromLibrary(name, f.path, index);
              },
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------
  // NETWORK HELPERS
  // -------------------------------------------------
  (String? artist, String title) _parseTitle(String raw) {
    var clean = raw;
    if (clean.contains('.')) {
      clean = clean.split('.').first;
    }
    if (clean.contains('-')) {
      final parts = clean.split('-');
      final artist = parts.first.trim();
      final title = parts.sublist(1).join('-').trim();
      return (artist, title);
    }
    return (null, clean.trim());
  }

  Future<void> _fetchLyricsFor(String trackName) async {
    setState(() {
      _lyricsLoading = true;
      _lyricsError = null;
      _lyricsText = null;
    });

    final parsed = _parseTitle(trackName);
    final artist = parsed.$1 ?? 'unknown';
    final title = parsed.$2;

    try {
      final uri = Uri.parse('https://api.lyrics.ovh/v1/$artist/$title');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _lyricsText = data['lyrics'] as String? ?? 'Lyrics found but empty.';
          _lyricsLoading = false;
        });
      } else {
        setState(() {
          _lyricsError = 'Lyrics not found (${res.statusCode}).';
          _lyricsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _lyricsError = 'Lyrics fetch error: $e';
        _lyricsLoading = false;
      });
    }
  }

  Future<void> _fetchInfoFor(String trackName) async {
    setState(() {
      _infoLoading = true;
      _infoError = null;
      _trackInfo = null;
    });

    final parsed = _parseTitle(trackName);
    final artist = parsed.$1;
    final title = parsed.$2;
    final q = artist != null ? '$artist $title' : title;

    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeQueryComponent(q)}&limit=1');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          setState(() {
            _trackInfo = results.first as Map<String, dynamic>;
            _infoLoading = false;
          });
        } else {
          setState(() {
            _infoError = 'No info found.';
            _infoLoading = false;
          });
        }
      } else {
        setState(() {
          _infoError = 'Info not found (${res.statusCode}).';
          _infoLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _infoError = 'Info fetch error: $e';
        _infoLoading = false;
      });
    }
  }
}
