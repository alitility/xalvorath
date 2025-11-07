import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../library/library_panel.dart';
import '../player/player_panel.dart';
import '../lyrics/lyrics_panel.dart';
import '../../core/services/ui_settings.dart';
import '../../app/routes.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiSettings>();
    final compact = ui.compactMode;
    final topBarHeight = compact ? 44.0 : 52.0;

    return Scaffold(
      backgroundColor: const Color(0xFF090A0E),
      body: Column(
        children: [
          // ---------------- TOP BAR ----------------
          Container(
            height: topBarHeight,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1014).withOpacity(0.6),
              border: const Border(
                bottom: BorderSide(color: Color(0x11FFFFFF)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Xalvorath Player',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                // search
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
          ),

          // ---------------- BODY ----------------
          Expanded(
            child: LayoutBuilder(
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
            ),
          ),
        ],
      ),
    );
  }
}
