# Papaya

## ![Icon](./source/icon.png?raw=true 'Icon')

### Build

flutter build apk --release --split-per-abi --split-debug-info --obfuscate

### Update Dependencies

flutter pub outdated  --prereleases --dependency-overrides --dev-dependencies

### Create Launch Icons

flutter pub run flutter_launcher_icons:main

### Native Splash

flutter pub run flutter_native_splash:create
flutter pub run flutter_native_splash:remove
