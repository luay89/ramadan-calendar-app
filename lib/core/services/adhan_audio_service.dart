import 'package:just_audio/just_audio.dart';

/// خدمة تشغيل صوت الأذان
class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();
  factory AdhanAudioService() => _instance;
  AdhanAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// تهيئة المشغل مع ملف الأذان
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _audioPlayer.setAsset('assets/audio/adhan.mp3');
      _isInitialized = true;
    } catch (e) {
      throw Exception('فشل في تحميل ملف الأذان: $e');
    }
  }

  /// تشغيل الأذان
  Future<void> playAdhan() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
  }

  /// إيقاف الأذان
  Future<void> stopAdhan() async {
    await _audioPlayer.stop();
  }

  /// إيقاف مؤقت
  Future<void> pauseAdhan() async {
    await _audioPlayer.pause();
  }

  /// استئناف التشغيل
  Future<void> resumeAdhan() async {
    await _audioPlayer.play();
  }

  /// التحقق من حالة التشغيل
  bool get isPlaying => _audioPlayer.playing;

  /// الحصول على مدة الأذان
  Duration? get duration => _audioPlayer.duration;

  /// الحصول على الموضع الحالي
  Duration get position => _audioPlayer.position;

  /// الاستماع لتغييرات الموضع
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// الاستماع لحالة التشغيل
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// تنظيف الموارد
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _isInitialized = false;
  }
}
