# Papaya

## ![Icon](./source/icon.png?raw=true 'Icon')

### Build

flutter build apk --release --split-per-abi --split-debug-info --obfuscate

### Update Dependencies

dart pub upgrade --null-safety --precompile

### Create Launch Icons

flutter pub run flutter_launcher_icons:main

### Native Splash

flutter pub run flutter_native_splash:create
flutter pub run flutter_native_splash:remove
