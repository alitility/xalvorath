import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/ui_settings.dart';

class LyricsPanel extends StatefulWidget {
  const LyricsPanel({super.key});

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  int _activeTab = 0; // 0: lyrics, 1: info, 2: queue

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final ui = context.watch<UiSettings>();

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

  Widget _lyricsView(AudioService audio) {
    return Padding(
      key: const ValueKey('lyrics'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        child: Text(
          audio.currentTitle != null
              ? "🎵 ${audio.currentTitle}\n\nŞarkı sözleri burada gösterilecek. "
                "Şu anda gerçek dosyadan çaldığımız için buraya ileride LRC / txt parser bağlayacağız.\n\n"
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
                "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n"
                "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
              : "Henüz bir şarkı seçilmedi.",
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _infoView(AudioService audio) {
    return Container(
      key: const ValueKey('info'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Track info', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoRow('Title', audio.currentTitle ?? '—'),
          _infoRow('Duration', audio.duration == Duration.zero
              ? '—'
              : '${audio.duration.inMinutes}:${(audio.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
          _infoRow('Position', audio.position == Duration.zero
              ? '—'
              : '${audio.position.inMinutes}:${(audio.position.inSeconds % 60).toString().padLeft(2, '0')}'),
          _infoRow('Source', 'Local file (PC)'),
          const SizedBox(height: 12),
          const Text(
            'Bu paneli sonra bitrate, codec, sample rate bilgisiyle dolduracağız.',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
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
                // queue'den de seçilebilir hale getir
                audio.playFromLibrary(name, f.path, index);
              },
            ),
          );
        },
      ),
    );
  }
}