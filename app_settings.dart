class AppSettings {
  const AppSettings({
    this.uiLanguage = 'uz',
    this.speechLocale = 'uz-UZ',
    this.voiceName = '',
    this.speechRate = 0.92,
    this.speechPitch = 1,
    this.speechVolume = 1,
    this.repeatCount = 1,
    this.snoozeMinutes = 10,
    this.themeMode = 'system',
    this.speakOnly = true,
  });

  final String uiLanguage;
  final String speechLocale;
  final String voiceName;
  final double speechRate;
  final double speechPitch;
  final double speechVolume;
  final int repeatCount;
  final int snoozeMinutes;
  final String themeMode;
  final bool speakOnly;

  factory AppSettings.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return const AppSettings();
    return AppSettings(
      uiLanguage: map['uiLanguage'] as String? ?? 'uz',
      speechLocale: map['speechLocale'] as String? ?? 'uz-UZ',
      voiceName: map['voiceName'] as String? ?? '',
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.92,
      speechPitch: (map['speechPitch'] as num?)?.toDouble() ?? 1,
      speechVolume: (map['speechVolume'] as num?)?.toDouble() ?? 1,
      repeatCount: (map['repeatCount'] as num?)?.toInt() ?? 1,
      snoozeMinutes: (map['snoozeMinutes'] as num?)?.toInt() ?? 10,
      themeMode: map['themeMode'] as String? ?? 'system',
      speakOnly: map['speakOnly'] as bool? ?? true,
    );
  }

  Map<String, Object?> toPlatformMap() => {
    'uiLanguage': uiLanguage,
    'speechLocale': speechLocale,
    'voiceName': voiceName,
    'speechRate': speechRate,
    'speechPitch': speechPitch,
    'speechVolume': speechVolume,
    'repeatCount': repeatCount,
    'snoozeMinutes': snoozeMinutes,
    'themeMode': themeMode,
    'speakOnly': speakOnly,
  };

  AppSettings copyWith({
    String? uiLanguage,
    String? speechLocale,
    String? voiceName,
    double? speechRate,
    double? speechPitch,
    double? speechVolume,
    int? repeatCount,
    int? snoozeMinutes,
    String? themeMode,
    bool? speakOnly,
  }) {
    return AppSettings(
      uiLanguage: uiLanguage ?? this.uiLanguage,
      speechLocale: speechLocale ?? this.speechLocale,
      voiceName: voiceName ?? this.voiceName,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speechVolume: speechVolume ?? this.speechVolume,
      repeatCount: repeatCount ?? this.repeatCount,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      themeMode: themeMode ?? this.themeMode,
      speakOnly: speakOnly ?? this.speakOnly,
    );
  }
}

class VoiceInfo {
  const VoiceInfo({
    required this.name,
    required this.localeTag,
    required this.language,
    required this.quality,
    required this.requiresNetwork,
    required this.isDefault,
  });

  final String name;
  final String localeTag;
  final String language;
  final int quality;
  final bool requiresNetwork;
  final bool isDefault;

  factory VoiceInfo.fromMap(Map<Object?, Object?> map) => VoiceInfo(
    name: map['name'] as String? ?? '',
    localeTag: map['localeTag'] as String? ?? '',
    language: map['language'] as String? ?? '',
    quality: (map['quality'] as num?)?.toInt() ?? 0,
    requiresNetwork: map['requiresNetwork'] as bool? ?? false,
    isDefault: map['isDefault'] as bool? ?? false,
  );
}

class DeviceCapabilities {
  const DeviceCapabilities({
    this.notificationGranted = false,
    this.exactAlarmGranted = false,
    this.speechRecognitionAvailable = false,
  });

  final bool notificationGranted;
  final bool exactAlarmGranted;
  final bool speechRecognitionAvailable;

  factory DeviceCapabilities.fromMap(Map<Object?, Object?>? map) =>
      DeviceCapabilities(
        notificationGranted: map?['notificationGranted'] as bool? ?? false,
        exactAlarmGranted: map?['exactAlarmGranted'] as bool? ?? false,
        speechRecognitionAvailable:
            map?['speechRecognitionAvailable'] as bool? ?? false,
      );
}
