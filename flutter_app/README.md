# Rabbit Hub Mobile App

Part 1 of Rabbit Hub is a local-first Flutter app for individual rabbit records. It runs independently from the Vite website in the repository root.

## Run

From this directory:

```powershell
flutter pub get
flutter run
```

For Android, connect a phone with USB debugging enabled or start an emulator. The Android SDK licenses must be accepted with `flutter doctor --android-licenses` before Android builds can run. For iOS, open the `ios/` project on macOS and run on a device or simulator.

## Local data

SQLite stores rabbits, photos metadata, weight records, history events, and settings in separate related tables. Rabbit photos are copied into the app documents directory. No account, server, cloud database, or network connection is needed for normal use.

The database is versioned and uses foreign keys for parent/offspring relationships. Timeline events have a typed event key so later breeding, litter, health, and medicine modules can add history without replacing the Part 1 records.

## Part 1 features

- Dashboard counts, recent records, and quick actions
- Rabbit create/edit, local camera/gallery photos, and main-photo selection
- Search by name, Rabbit ID, ear tag, breed, and color; gender/status filters
- Rabbit profile with family, notes, multiple photos, weight history, and timeline
- Persistent rabbitry name, weight unit, date format, and theme settings
- Events placeholder for the next app part

## Verify

```powershell
flutter analyze
flutter test
flutter build windows
```