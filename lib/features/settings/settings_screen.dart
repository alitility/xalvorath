import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/ui_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiSettings>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Interface',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Compact layout'),
            subtitle: const Text('Use tighter paddings for small screens'),
            value: ui.compactMode,
            onChanged: ui.setCompact,
          ),
          SwitchListTile(
            title: const Text('Glow effects'),
            subtitle: const Text('Panel shadows and accent highlights'),
            value: ui.glowEffects,
            onChanged: ui.setGlow,
          ),
          const SizedBox(height: 12),
          const Text(
            'Xalvorath mode',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Demon mode'),
            subtitle: const Text('Use red / hell palette'),
            value: ui.demonMode,
            onChanged: ui.setDemonMode,
          ),
          SwitchListTile(
            title: const Text('Idle glow'),
            subtitle: const Text('Pulse when player is paused'),
            value: ui.idleGlow,
            onChanged: ui.setIdleGlow,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Theme pulse intensity'),
            subtitle: Slider(
              value: ui.pulseIntensity,
              min: 0.2,
              max: 2.0,
              onChanged: ui.setPulseIntensity,
            ),
            trailing: Text(ui.pulseIntensity.toStringAsFixed(1)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keybinds (coming soon)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const ListTile(
            title: Text('Play/Pause → Space'),
            subtitle: Text('Will be configurable'),
          ),
          const ListTile(
            title: Text('Next / Previous → Ctrl + ←/→'),
            subtitle: Text('Will be configurable'),
          ),
        ],
      ),
    );
  }
}
