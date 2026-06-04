# TriggerTrace

A cross-platform Flutter app for tracking food intake and health symptoms with AI-powered pattern recognition and correlation analysis. Designed for people with eczema, food sensitivities, and allergies.

## Features

### Food & Health Diary
- **5 meal categories**: Drinks, Breakfast, Lunch, Dinner, Snacks
- Ingredient tracking per meal
- Health metrics on a 0-10 scale (allergy symptoms, energy, sleep quality, stress)
- Menstruation tracking
- Notes and timestamps

### AI Analysis Engine
- **Pattern detection**: Identifies recurring food and health patterns
- **Correlation analysis**: Discovers relationships between food and symptoms
- **Smart recommendations**: AI-generated suggestions based on your data
- **Confidence scores**: Shows the strength of each detected pattern

### Elimination Diet Protocol
- Guided elimination diet phases
- Track which foods to avoid and reintroduce
- Monitor symptom changes during elimination

### Premium (via RevenueCat)
- In-app subscription with 7-day free trial
- Unlocks full AI analysis, elimination diet features, and more

## Tech Stack

- **Framework**: Flutter 3.x (Dart)
- **State Management**: Provider
- **In-App Purchases**: RevenueCat (`purchases_flutter`)
- **Charts**: fl_chart
- **Local Storage**: SharedPreferences
- **CI/CD**: Codemagic
- **Distribution**: Apple App Store

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── analyse_resultaat.dart
│   ├── dagboek_entry.dart
│   ├── eliminatie_test.dart
│   ├── gezondheids_metric.dart
│   ├── voedsel_categorie.dart
│   └── voedsel_entry.dart
├── providers/
│   └── dagboek_provider.dart
├── screens/
│   ├── analyse_screen.dart
│   ├── bewerk_screen.dart
│   ├── dagboek_detail_screen.dart
│   ├── dagboek_screen.dart
│   ├── eliminatie_screen.dart
│   ├── grafiek_view.dart
│   ├── home_screen.dart
│   ├── paywall_screen.dart
│   ├── profiel_screen.dart
│   └── toevoegen_screen.dart
├── services/
│   ├── ai_analyse_service.dart
│   └── purchases_service.dart
└── widgets/
    ├── app_logo.dart
    └── home_button.dart
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on iOS simulator (macOS only)
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Build iOS release (via Codemagic)
# Zie CODEMAGIC.md en codemagic.yaml
```

### Codemagic (iOS CI/CD)

1. Koppel repo [EczemaCare](https://github.com/RObzegt/EczemaCare) in Codemagic.
2. Volg **[CODEMAGIC.md](CODEMAGIC.md)** (integratie, signing, env groups).
3. Eerst workflow **ios-verify**, daarna **ios-release** (TestFlight).

## Privacy

- All health data is stored locally on the device
- Privacy Policy: https://robzegt.github.io/EczemaCare/Privacy.html
- Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

## License

Proprietary. All rights reserved.
