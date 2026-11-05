# VOICE LIFE

VOICE LIFE is an offline-first Flutter app for Android. Reminder records and
settings are stored in Android's local SQLite database. Android `AlarmManager`,
receivers, and a foreground Text-to-Speech service handle scheduled speech;
Flutter timers are used only to refresh the on-screen clock.

## Source status

This folder contains the complete source project. **An APK has not been built,
installed, or tested.** This environment did not have Flutter, Android SDK,
Gradle, or a connected Android device. The Uzbek voice check reports the TTS
voices the device exposes; it does not establish that a voice sounds natural.
Use the in-app voice preview and the real-device checklist below before
describing Uzbek speech quality.

## Open and run

Requirements:

- Flutter 3.29 or newer, with Dart included
- Android Studio with Android SDK and platform tools
- JDK 17
- An Android device or emulator running Android 6.0 (API 23) or newer

1. Open the `voice-life` folder in Android Studio with the Flutter and Dart
   plugins installed. Do not open the `android` subfolder as a separate
   Flutter project.
2. Install the Android SDK platform/build tools requested by Android Studio.
3. Run `flutter pub get`.
4. Connect an Android device or start an emulator, then run `flutter run`.
5. Grant notification and exact-alarm access when prompted. In Android's
   Text-to-Speech settings, install an Uzbek voice if the device offers one.
6. In VOICE LIFE settings, select Uzbek speech and use **Preview voice**.
   This tests that installed engine on that device; it is not a substitute for
   listening to reminder text in real conditions.

Application ID: `com.voicelife.reminder`.

## Release signing and APK

The project deliberately does not include a signing key. Create and protect a
keystore yourself; losing it prevents updates signed with that key.

From the `voice-life` directory, create a keystore outside source control:

```sh
keytool -genkeypair -v \
  -keystore android/voice-life-release.jks \
  -alias voice-life \
  -keyalg RSA -keysize 2048 -validity 10000
```

Create `android/key.properties` locally (it is ignored by Git):

```properties
storeFile=voice-life-release.jks
storePassword=REPLACE_WITH_YOUR_KEYSTORE_PASSWORD
keyAlias=voice-life
keyPassword=REPLACE_WITH_YOUR_KEY_PASSWORD
```

Keep the keystore and passwords private and backed up securely. Do not commit
them or paste them into chat. Then build:

```sh
flutter pub get
flutter build apk --release
```

The installable APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. The Gradle release task stops
if the local signing configuration or keystore is missing. No signed APK or
keystore is included in this source project.

## Install the generated APK

Copy the APK to the Android phone and open it with the Files app. If Android
asks, allow **Install unknown apps** for that file-opening app, confirm the
installation, then turn that permission off again if it is no longer needed.
Future updates must be signed with the same private keystore used for this APK.

## Uzbek speech behavior

- The app asks Android TTS for installed voices whose reported language is
  exactly Uzbek (`uz`). Voice names and locale tags come from the device TTS
  engine; the app does not label Russian, English, or another locale as Uzbek.
- If no matching Uzbek voice is reported, scheduled Uzbek reminders are not
  spoken with a different language voice. A silent notification explains that
  the selected TTS voice is unavailable.
- The app exposes installed device voices, speed, pitch, volume, repeat count,
  and a preview. Android's voice list does not reliably expose speaker gender,
  so VOICE LIFE does not invent male/female labels.
- Device voice quality, Uzbek pronunciation, prosody, numbers, and network
  dependence vary by TTS engine. None have been evaluated here. No cloud TTS
  provider is configured.
- Voice-command transcription uses Android's installed speech-recognition
  service and requests offline recognition where available. Some services may
  still require internet. VOICE LIFE does not save audio recordings; review the
  recognition provider's privacy terms on the device.

## Reminders and Android limits

- Each reminder is stored in SQLite before an Android alarm is scheduled.
  Daily, weekly (selected weekdays), monthly, and one-time schedules are
  supported.
- Exact alarms require the Android **Alarms & reminders** access on recent
  Android versions. If it is unavailable, the app uses Android's inexact
  idle-capable alarm as a best-effort fallback and warns that delivery may be
  delayed. That fallback is not equivalent to an exact alarm.
- Android notification permission is separate. Without it, the device may hide
  the visual reminder controls even if speech starts.
- On boot, app replacement, clock changes, and time-zone changes, the receiver
  rebuilds pending alarms from SQLite and the saved local date/time. A reminder
  interrupted while ringing is replayed after reboot.
- Speech uses a foreground media-playback service and one-at-a-time queue. The
  notification channel is created silent with vibration disabled. A device
  maker, TTS engine, audio route, Do Not Disturb policy, or battery manager can
  still affect playback.
- **Force-stop is a hard Android limit:** after a user force-stops the app,
  Android suppresses its alarms and receivers until the app is opened again.
  VOICE LIFE cannot bypass that restriction. Open the app again after force
  stopping it.
- Some manufacturers pause background work unless the app is exempted from
  battery optimization or allowed to autostart. The app links to Android's
  battery settings, but the setting and behavior vary by manufacturer.

## Privacy and backup

No account or cloud storage is used. Reminders and settings stay in the app's
SQLite database; Android app backup is disabled. A user-initiated backup writes
a JSON file through Android's document picker. Restore replaces existing
reminders, settings, and history, and asks for confirmation first. The chosen
backup file may be stored wherever the user selects.

## Real-device verification checklist

Before release, verify on supported Android versions and at least one
manufacturer-customized Android device:

1. Install a real Uzbek TTS voice if offered; inspect its locale in settings,
   listen to previews containing `O‘`, `G‘`, `Sh`, `Ch`, `Ng`, dates, times, and
   numbers, and assess actual Uzbek fluency.
2. Schedule one-time, daily, weekly, and monthly reminders; lock the screen and
   confirm the full text is spoken without an alarm tone, ringtone, or beep.
3. Verify reminder notification actions, Done, Snooze, repeat count, and that
   two reminders never speak over each other.
4. Restart the device and confirm alarms return. Change the time zone and
   system clock and confirm local wall-clock times remain correct.
5. Test with exact-alarm and notification permissions denied, then granted;
   test battery optimization, Do Not Disturb, headphones/Bluetooth, silent
   mode, and the device's TTS engine unavailable.
6. Force-stop the app, observe that Android suppresses delivery, reopen it,
   and verify future reminders are scheduled again.
7. Export a backup, restore it onto a test install, and verify the replacement
   warning and restored reminder/settings/history data.

`tool/verify_uzbek_parser.dart` is a dependency-free smoke check for the Uzbek
voice-command date/time parser and can be run with:

```sh
dart --enable-asserts tool/verify_uzbek_parser.dart
```

With Flutter installed, run `flutter test` to execute the parser unit tests in
`test/`.
