import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  String? _currentTitle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  List<FileSystemEntity> _libraryFiles = [];
  int _currentIndex = -1;

  String? get currentTitle => _currentTitle;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  List<FileSystemEntity> get libraryFiles => _libraryFiles;
  int get currentIndex => _currentIndex;

  AudioService() {
    _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      if (d != null) {
        _duration = d;
        notifyListeners();
      }
    });
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> init() async {
    try {
      await _player.setVolume(1.0);
    } catch (e) {
      debugPrint('Audio init error: $e');
    }
  }

  void setLibraryFiles(List<FileSystemEntity> files) {
    _libraryFiles = files;
    notifyListeners();
  }

  Future<void> pickAndPlay() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result == null) return;
    final path = result.files.single.path!;
    final name = result.files.single.name;
    await _playFromPath(name, path);
    _currentIndex = -1;
  }

  Future<void> playFromLibrary(String title, String path, int index) async {
    _currentIndex = index;
    await _playFromPath(title, path);
  }

  Future<void> _playFromPath(String title, String path) async {
    try {
      final fixedPath = path.replaceAll(r'\', '/');
      if (!File(fixedPath).existsSync()) {
        debugPrint('File not found: $fixedPath');
        return;
      }

      _currentTitle = title;
      await _player.setFilePath(fixedPath);
      await _player.play();
      _isPlaying = true;
      notifyListeners();
      debugPrint('Now playing: $title');
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      _isPlaying = false;
    } else {
      await _player.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> seekToFraction(double value) async {
    if (_duration == Duration.zero) return;
    final targetMs = (_duration.inMilliseconds * value).toInt();
    await _player.seek(Duration(milliseconds: targetMs));
  }

  Future<void> next() async {
    if (_libraryFiles.isEmpty || _currentIndex == -1) return;
    final nextIndex = _currentIndex + 1;
    if (nextIndex >= _libraryFiles.length) return;
    final file = _libraryFiles[nextIndex];
    final name = file.path.split(Platform.pathSeparator).last;
    await playFromLibrary(name, file.path, nextIndex);
  }

  Future<void> previous() async {
    if (_libraryFiles.isEmpty || _currentIndex <= 0) return;
    final prevIndex = _currentIndex - 1;
    final file = _libraryFiles[prevIndex];
    final name = file.path.split(Platform.pathSeparator).last;
    await playFromLibrary(name, file.path, prevIndex);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
