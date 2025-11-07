import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/ui_settings.dart';
import '../library/library_panel.dart';
import '../player/player_panel.dart';
import '../lyrics/lyrics_panel.dart';
import '../../app/routes.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  bool _showVolume = false;
  double _volume = 1.0;
  bool _showSearch = false;
  Timer? _hideTimer;

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiSettings>();
    final compact = ui.compactMode;
    final audio = context.watch<AudioService>();
    final isPlaying = audio.isPlaying;
    final topBarHeight = compact ? 44.0 : 52.0;

    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (event) {
        if (event.isControlPressed && event.logicalKey.keyLabel.toLowerCase() == 'k') {
          setState(() => _showSearch = !_showSearch);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090A0E),
        body: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(context, topBarHeight, compact),
                Expanded(child: _buildPanels(context, compact)),
              ],
            ),
            _buildMiniPlayer(context, audio),
            _buildVolumeOverlay(context),
            if (_showSearch) _buildSearchOverlay(context),
            if (!isPlaying)
              AnimatedOpacity(
                opacity: 0.25,
                duration: const Duration(milliseconds: 300),
                child: Container(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, double height, bool compact) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1014).withOpacity(0.6),
        border: const Border(bottom: BorderSide(color: Color(0x11FFFFFF))),
      ),
      child: Row(
        children: [
          const Text(
            'Xalvorath Player',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: compact ? 28 : 32,
              decoration: BoxDecoration(
                color: const Color(0x22000000),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                onChanged: (val) {
                  context.read<UiSettings>().setLibraryQuery(val);
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, size: 16, color: Colors.white54),
                  hintText: 'Search in library…',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
            icon: const Icon(Icons.settings_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPanels(BuildContext context, bool compact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final totalH = constraints.maxHeight;

        double libW;
        double playerW;
        double lyricsW;
        bool showLyrics = true;

        if (totalW < 1050) {
          showLyrics = false;
          libW = totalW * 0.26;
          playerW = totalW - libW;
          lyricsW = 0;
        } else {
          libW = totalW * 0.22;
          playerW = totalW * 0.34;
          lyricsW = totalW - libW - playerW;

          if (lyricsW < 230) {
            final need = 230 - lyricsW;
            playerW -= need;
            lyricsW = 230;
          }
        }

        if (compact && showLyrics) {
          libW *= 0.95;
          playerW *= 0.97;
          lyricsW *= 0.97;
        }

        const d = Duration(milliseconds: 320);
        const c = Curves.easeOutCubic;

        return Row(
          children: [
            AnimatedContainer(
              duration: d,
              curve: c,
              width: libW,
              height: totalH,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B5CFF).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const LibraryPanel(),
            ),
            AnimatedContainer(
              duration: d,
              curve: c,
              width: playerW,
              height: totalH,
              child: const PlayerPanel(),
            ),
            AnimatedSwitcher(
              duration: d,
              switchInCurve: c,
              switchOutCurve: Curves.easeInCubic,
              child: showLyrics
                  ? AnimatedContainer(
                      key: const ValueKey('lyrics'),
                      duration: d,
                      curve: c,
                      width: lyricsW,
                      height: totalH,
                      child: const LyricsPanel(),
                    )
                  : const SizedBox.shrink(key: ValueKey('nolyrics')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniPlayer(BuildContext context, AudioService audio) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF11131A).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B5CFF).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: audio.previous,
            ),
            IconButton(
              icon: Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: audio.togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: audio.next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeOverlay(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 70,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _showVolume = true);
          _hideTimer?.cancel();
        },
        onExit: (_) {
          _hideTimer = Timer(const Duration(seconds: 2), () {
            setState(() => _showVolume = false);
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showVolume ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF11131A).withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B5CFF).withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: RotatedBox(
              quarterTurns: -1,
              child: SizedBox(
                width: 100,
                child: Slider(
                  value: _volume,
                  onChanged: (v) => setState(() => _volume = v),
                  activeColor: const Color(0xFF7B5CFF),
                  inactiveColor: Colors.white24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF11131A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B5CFF).withOpacity(0.5),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quick Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type to search...',
                filled: true,
                fillColor: const Color(0x22000000),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() => _showSearch = false),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
