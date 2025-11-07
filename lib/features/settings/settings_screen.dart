import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/ui_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiSettings>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Görünüm'),
            subtitle: Text('Xalvorath arayüz tercihleri'),
          ),
          SwitchListTile(
            title: const Text('Compact mode'),
            subtitle: const Text('Panel aralıklarını ve paddingleri küçült'),
            value: ui.compactMode,
            onChanged: (val) {
              context.read<UiSettings>().setCompact(val);
            },
          ),
          SwitchListTile(
            title: const Text('Glow effects'),
            subtitle: const Text('Player aktifken parıltı ver'),
            value: ui.glowEffects,
            onChanged: (val) {
              context.read<UiSettings>().setGlow(val);
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Hakkında'),
            subtitle: Text('Xalvorath PC skeleton • modular'),
          ),
        ],
      ),
    );
  }
}
