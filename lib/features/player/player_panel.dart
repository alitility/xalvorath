import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/ui_settings.dart';

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key});

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final ui = context.watch<UiSettings>();

    final currentTitle = audio.currentTitle;
    final isPlaying = audio.isPlaying;
    final pos = audio.position;
    final dur = audio.duration.inSeconds == 0 ? const Duration(seconds: 1) : audio.duration;
    final progress = pos.inMilliseconds / dur.inMilliseconds;
    final glow = ui.glowEffects && isPlaying;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      decoration: BoxDecoration(
        color: const Color(0xFF101218),
        border: const Border(
          right: BorderSide(
            color: Color(0xFF101218), // gizli çizgi
            width: 1,
          ),
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFF7B5CFF).withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // artwork
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: isPlaying ? 230 : 210,
                height: isPlaying ? 230 : 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B5CFF), Color(0xFF191B22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(Icons.music_note, size: 70),
              ),
              const SizedBox(height: 20),
              Text(
                currentTitle ?? 'Henüz bağlı değil',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                currentTitle == null
                    ? 'Select a track from the left'
                    : isPlaying
                        ? 'Playing from Library'
                        : 'Paused',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 18),

              // progress
              Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (_) {},
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(pos),
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  Text(
                    _format(dur),
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous, size: 26)),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AudioService>().togglePlayPause();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B5CFF),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
                  ),
                  const SizedBox(width: 12),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next, size: 26)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
