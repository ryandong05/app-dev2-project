# Y

A twitter clone.

# Getting Started

Before you begin, ensure you have met the following requirements:

- Flutter SDK (version 3.7.2 or higher)
- Dart SDK
- Firebase CLI
- Node.js (OPTIONAL)
- An IDE (VS Code or Android Studio recommended)
- Flutter and Dart plugins for your IDE

## Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd app-dev2-project
   ```

2. Install [Firebase CLI](https://firebase.google.com/docs/cli#install-cli-windows) to login and setup api keys
   ```bash
   npm install -g firebase-tools #or download the executable
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Powershell (Windows)
   ```pwsh
   & "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire" configure
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

## Running the Project

You can run the project on different platforms:

### Web
```bash
flutter run -d chrome
```

### Android
```bash
flutter run -d <android-device-id>
```

### iOS (requires macOS)
```bash
flutter run -d <ios-device-id>
```

### Windows
```bash
flutter run -d windows
```

## Additional Commands

- Check available devices: `flutter devices`
- Clean the project: `flutter clean`
- Update dependencies: `flutter pub upgrade`

## Dependencies

- Flutter SDK
- intl: ^0.18.1 (for internationalization)
- cupertino_icons: ^1.0.8 (for iOS-style icons)

