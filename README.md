# GezondheidsTracker - Flutter App met AI Analyse

Een geavanceerde cross-platform app voor het bijhouden van voedselinname en gezondheidssymptomen met AI-gedreven patroonherkenning en correlatie analyse.

## 🚀 Waarom Flutter?

- ✅ **Cross-platform**: Werkt op iOS, Android, Web en Desktop
- ✅ **Ontwikkel op Windows**: Geen Mac of Xcode nodig!
- ✅ **Hot Reload**: Zie direct je wijzigingen
- ✅ **Visual Studio Code**: Gratis en krachtige IDE
- ✅ **Één codebase**: Bespaar ontwikkeltijd

## 📱 Features

### Voedsel Tracking
- **5 Categorieën**: Drinken, Ontbijt, Lunch, Diner, Snack
- Ingrediënten registratie
- Tijdstip logging
- Notities per maaltijd

### Gezondheids Monitoring
- **Allergie symptomen** (0-10 schaal)
- **Energie niveau** (0-10 schaal)
- **Slaap kwaliteit** (0-10 schaal)
- **Stress niveau** (0-10 schaal)
- **Ongesteldheid** tracking
- Optionele notities

### AI Analyse
- **Patroon detectie**: Identificeert terugkerende voedsel- en gezondheidspatronen
- **Correlatie analyse**: Ontdekt relaties tussen voedsel en symptomen
- **Slimme aanbevelingen**: AI-gegenereerde suggesties gebaseerd op je data
- **Betrouwbaarheidsscores**: Toont hoe sterk elk patroon is

## 🏗️ Projectstructuur

```
GezondheidsTrackerFlutter/
├── pubspec.yaml                      # Dependencies & configuratie
├── lib/
│   ├── main.dart                     # App entry point
│   ├── models/                       # Data models
│   │   ├── voedsel_categorie.dart
│   │   ├── voedsel_entry.dart
│   │   ├── gezondheids_metric.dart
│   │   ├── dagboek_entry.dart
│   │   └── analyse_resultaat.dart
│   ├── providers/                    # State management (Provider)
│   │   └── dagboek_provider.dart
│   ├── services/                     # Business logic
│   │   └── ai_analyse_service.dart
│   └── screens/                      # UI Screens
│       ├── home_screen.dart
│       ├── dagboek_screen.dart
│       ├── dagboek_detail_screen.dart
│       ├── toevoegen_screen.dart
│       └── analyse_screen.dart
└── README.md
```

## 🛠️ Installatie & Setup

### 1. Installeer Flutter

**Windows:**
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract naar `C:\src\flutter`
3. Voeg toe aan PATH: `C:\src\flutter\bin`
4. Open terminal en run: `flutter doctor`

**Mac/Linux:**
```bash
# Volg instructies op: https://docs.flutter.dev/get-started/install
```

### 2. Installeer Visual Studio Code

1. Download: https://code.visualstudio.com/
2. Installeer Flutter extensie in VS Code
3. Installeer Dart extensie in VS Code

### 3. Setup Project

```bash
# Navigeer naar project folder
cd c:\Down\orions2\GezondheidsTrackerFlutter

# Install dependencies
flutter pub get

# Check of alles werkt
flutter doctor
```

### 4. Run de App

**In Browser (Web):**
```bash
flutter run -d chrome
```

**Android Emulator:**
```bash
# Start Android Studio > AVD Manager > Start emulator
flutter run -d android
```

**iOS Simulator (alleen Mac):**
```bash
flutter run -d ios
```

**Desktop (Windows):**
```bash
flutter run -d windows
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  intl: ^0.19.0            # Datum formattering (NL)
  uuid: ^4.2.2             # Unieke ID's
  shared_preferences: ^2.2.2  # Lokale opslag
```

## 💻 Ontwikkel Workflow

### VS Code Shortcuts
- `F5` - Start debugging
- `Shift + F5` - Stop debugging
- `Ctrl + Shift + P` - Command palette
- `r` - Hot reload (tijdens run)
- `R` - Hot restart (tijdens run)
- `p` - Toggle performance overlay

### Flutter Commands
```bash
# Run app
flutter run

# Build release APK (Android)
flutter build apk --release

# Build voor web
flutter build web

# Clean project
flutter clean

# Update dependencies
flutter pub upgrade

# Analyze code
flutter analyze
```

## 🎯 Gebruik

### 1. Dagboek Tabblad
- Bekijk al je dagboek entries chronologisch
- Tap op delete icon om entries te verwijderen
- Tap op card voor gedetailleerde weergave

### 2. Toevoegen Tabblad
**Voedsel invoeren:**
- Selecteer categorie (Drinken/Ontbijt/Lunch/Diner/Snack)
- Beschrijf wat je gegeten/gedronken hebt
- Voeg ingrediënten toe (gescheiden door komma's)
- Kies datum en tijd
- Voeg optionele notities toe

**Gezondheid invoeren:**
- Beweeg sliders voor verschillende metrics (0-10)
- Vink ongesteldheid aan indien van toepassing
- Kies datum en tijd
- Voeg context toe via notities

### 3. Analyse Tabblad
- Druk op "Start AI Analyse"
- Bekijk gevonden patronen
- Check correlaties tussen voedsel en symptomen
- Lees persoonlijke aanbevelingen

## 🤖 AI Analyse Engine

De app gebruikt een geavanceerd analyse algoritme dat:

### Patroon Detectie
- Identificeert veelvoorkomende voedselitems (≥3x)
- Detecteert ongesteldheidspatronen
- Herkent energie-gerelateerde trends
- Berekent betrouwbaarheidsscores

### Correlatie Berekening
- Vergelijkt gezondheidsmetrics met vs zonder specifiek voedsel
- Berekent statistische correlaties (-1.0 tot 1.0)
- Filtert significante relaties (≥2.0 verschil)
- Sorteert op sterkte

### Slimme Aanbevelingen
- Waarschuwt voor negatieve correlaties (allergiën)
- Benadrukt positieve effecten (energie boosters)
- Geeft algemene gezondheidsadvies
- Vraagt om meer data voor betere inzichten

## 🎨 UI Components

- **Material Design 3**: Modern design language
- **Bottom Navigation**: Eenvoudige navigatie tussen tabs
- **Cards & Lists**: Duidelijke data presentatie
- **Sliders**: Intuïtieve metric invoer
- **Progress Indicators**: Visual feedback tijdens analyse
- **Responsive**: Past zich aan verschillende schermgroottes

## 🔒 Privacy & Data

- Alle data blijft lokaal op je device
- Geen externe API calls
- Optioneel: SharedPreferences voor persistentie
- Uitbreidbaar met Firebase/Supabase voor cloud sync

## 🚀 Roadmap & Uitbreidingen

### Korte Termijn
- [x] Basis functionaliteit
- [x] AI analyse engine
- [x] Material Design UI
- [ ] Persistentie met SharedPreferences
- [ ] Data export (CSV/JSON)
- [ ] Zoekfunctie

### Lange Termijn
- [ ] Grafieken en charts (fl_chart package)
- [ ] Cloud sync met Firebase
- [ ] Push notifications herinneringen
- [ ] Foto's toevoegen aan maaltijden
- [ ] Barcode scanner voor producten
- [ ] Dark mode
- [ ] Meerdere talen
- [ ] Widget voor snelle invoer

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
```

## 📱 Build voor Productie

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

### iOS (alleen Mac)
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

### Windows Desktop
```bash
flutter build windows --release
```

## 💡 Tips voor Beste Resultaten

1. **Consistente invoer**: Dagelijks bijhouden geeft betere patronen
2. **Specifieke ingrediënten**: Meer detail = betere correlaties
3. **Eerlijke metrics**: Nauwkeurige sliderwaarden zijn cruciaal
4. **Notities gebruiken**: Context helpt bij interpretatie
5. **Minimaal 7 dagen data**: Voor betrouwbare analyse
6. **Regelmatige analyse**: Check wekelijks voor nieuwe inzichten

## 🎓 Leer Doelen

Dit project demonstreert:
- Flutter framework basics
- Provider state management
- Material Design 3
- Dart programming
- Async/await patterns
- JSON serialization
- List operations
- Date/time handling
- Cross-platform development

## 🐛 Troubleshooting

### Flutter doctor issues
```bash
flutter doctor -v
# Volg de suggesties om problemen op te lossen
```

### Dependencies niet gevonden
```bash
flutter clean
flutter pub get
```

### Hot reload werkt niet
```bash
# Stop de app en herstart met:
flutter run
```

## 📄 Licentie

Dit is een educatief/demo project. Pas aan naar je eigen behoeften!

## 🤝 Contributie

Suggesties en verbeteringen zijn welkom!

---

**Belangrijk**: Deze app is bedoeld als hulpmiddel en vervangt geen medisch advies. Raadpleeg altijd een professional bij gezondheidsklachten.

## 📞 Support

Heb je vragen? Check:
- Flutter docs: https://docs.flutter.dev/
- Dart docs: https://dart.dev/guides
- Flutter Community: https://flutter.dev/community
