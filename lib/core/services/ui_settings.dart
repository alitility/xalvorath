import 'package:flutter/material.dart';

class UiSettings extends ChangeNotifier {
  // 🔹 Görsel ayarlar
  Color _accentColor = const Color(0xFF7B5CFF);
  bool _glowEffects = true;

  // 🔹 Kullanıcı arayüz tercihleri
  bool _compactMode = false;
  String? _activePlaylist;
  String _libraryQuery = '';

  // === GETTER ===
  Color get accentColor => _accentColor;
  bool get glowEffects => _glowEffects;
  bool get compactMode => _compactMode;
  String? get activePlaylist => _activePlaylist;
  String get libraryQuery => _libraryQuery;

  // === SETTER ===
  void setAccent(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
  }

  // settings_screen.dart içinde çağrılan isimler:
  void setGlow(bool value) {
    _glowEffects = value;
    notifyListeners();
  }

  void setCompact(bool value) {
    _compactMode = value;
    notifyListeners();
  }

  void toggleGlow() {
    _glowEffects = !_glowEffects;
    notifyListeners();
  }

  void toggleCompactMode() {
    _compactMode = !_compactMode;
    notifyListeners();
  }

  void setActivePlaylist(String? playlist) {
    _activePlaylist = playlist;
    notifyListeners();
  }

  void setLibraryQuery(String query) {
    _libraryQuery = query;
    notifyListeners();
  }
}
