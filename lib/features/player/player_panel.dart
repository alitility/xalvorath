import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/ui_settings.dart';

class PlayerPanel extends StatefulWidget {
  const PlayerPanel({super.key});

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();
    final ui = context.watch<UiSettings>();
    final accent = ui.accentColor;
    final glow = ui.glowEffects;

    final title = audio.currentTitle ?? 'No song';
    final pos = audio.position;
    final dur = audio.duration;

    // eğer şarkı yoksa (süre 0) bu panel tıklamayı geçirsin
    final bool shouldPassClicks = dur.inMilliseconds == 0;

    final progress = dur.inMilliseconds == 0
        ? 0.0
        : pos.inMilliseconds / dur.inMilliseconds;

    return IgnorePointer(
      ignoring: shouldPassClicks,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF08090C),
              accent.withOpacity(0.15),
              const Color(0xFF08090C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SADECE kapak kısmı çift tık yakalıyor
            GestureDetector(
              onDoubleTapDown: (details) {
                const w = 160.0;
                if (details.localPosition.dx < w / 2) {
                  audio.previous();
                } else {
                  audio.next();
                }
              },
              child: ScaleTransition(
                scale: _pulseController,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accent.withOpacity(0.6),
                        accent.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: glow
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black12,
                    child: Icon(
                      Icons.music_note,
                      size: 56,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              audio.isPlaying ? 'Playing…' : 'Paused',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // waveform
            SizedBox(
              height: 40,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _WavePainter(
                      _waveController.value,
                      accent,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // slider
            Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (val) => audio.seekToFraction(val),
              activeColor: accent,
              inactiveColor: Colors.white12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(pos), style: const TextStyle(fontSize: 12)),
                  Text(_format(dur), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 32),
                  onPressed: audio.previous,
                ),
                const SizedBox(width: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: IconButton(
                    key: ValueKey(audio.isPlaying),
                    icon: Icon(
                      audio.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 56,
                      color: accent,
                    ),
                    onPressed: audio.togglePlayPause,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 32),
                  onPressed: audio.next,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _WavePainter extends CustomPainter {
  final double value;
  final Color color;
  final int bars = 32;

  _WavePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final rand = Random(value.hashCode);
    final barWidth = size.width / bars;

    for (int i = 0; i < bars; i++) {
      final x = i * barWidth;
      final h = (sin(value * 2 * pi + i) + 1) * 0.4 + rand.nextDouble() * 0.3;
      final y = size.height * (1 - h);
      canvas.drawLine(Offset(x, size.height), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
