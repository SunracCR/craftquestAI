/// Catalog entry for a selectable practice background music track.
class PracticeMusicTrack {
  const PracticeMusicTrack({
    required this.assetPath,
    required this.label,
  });

  final String assetPath;
  final String label;
}

abstract final class AudioAssets {
  static const trackCount = 9;

  static const List<PracticeMusicTrack> musicTrackCatalog = [
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/77HertzFrequency.mp3',
      label: '77HertzFrequency',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/CalmRain.mp3',
      label: 'CalmRain',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/CalmWaves.mp3',
      label: 'CalmWaves',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/ChillStudy.mp3',
      label: 'ChillStudy',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/EgyptianMetal.mp3',
      label: 'EgyptianMetal',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/Kaazoom.mp3',
      label: 'Kaazoom',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/MeditativeWhiteNoise.mp3',
      label: 'MeditativeWhiteNoise',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/MoodChillInstrumental.mp3',
      label: 'MoodChillInstrumental',
    ),
    PracticeMusicTrack(
      assetPath: 'assets/audio/music/SportMetal.mp3',
      label: 'SportMetal',
    ),
  ];

  static const sfxStart = 'assets/audio/sfx/sfx_start.mp3';
  static const sfxNav = 'assets/audio/sfx/sfx_nav.mp3';
  static const sfxFinish = 'assets/audio/sfx/sfx_finish.mp3';

  static String musicTrack(int index) {
    final clamped = index.clamp(0, musicTrackCatalog.length - 1);
    return musicTrackCatalog[clamped].assetPath;
  }

  static String musicTrackLabel(int index) {
    final clamped = index.clamp(0, musicTrackCatalog.length - 1);
    return musicTrackCatalog[clamped].label;
  }
}
