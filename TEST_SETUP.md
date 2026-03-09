# 🧪 GezondheidsTracker - Test Setup Guide

## ✅ Fixes Applied

I've fixed the following issues to make the app ready for testing:

### 1. **Missing `getWeekNumber()` Function** ✓
- Added ISO 8601 week number calculation to `ai_analyse_service.dart`
- This fixes compilation errors in the analysis engine

### 2. **Analyse Screen Navigation** ✓
- Added third navigation tab for "Analyse" screen
- Now accessible via bottom navigation bar
- Uses analytics icon for visual consistency

## 🚀 Quick Start - Testing the App

### Option 1: Test in Chrome (Recommended for Windows)

```powershell
# 1. Install Flutter (if not already installed)
# Download from: https://docs.flutter.dev/get-started/install/windows
# Or use: winget install --id=Google.Flutter -e

# 2. Add Flutter to PATH
$env:Path += ";C:\flutter\bin"  # Adjust path as needed

# 3. Navigate to project
cd "C:\Down\orions2\GezondheidsTrackerFlutter"

# 4. Get dependencies
flutter pub get

# 5. Run in Chrome
flutter run -d chrome
```

### Option 2: Test on Android Emulator

```powershell
# 1. Install Android Studio and create AVD
# 2. Start emulator
# 3. Run:
flutter run -d android
```

### Option 3: Test on Windows Desktop

```powershell
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Build and run
flutter run -d windows
```

## 🧪 Test Scenarios

### 1. **Dagboek Tab (Entry List)**
- [ ] View chronological list of entries
- [ ] Delete entries using trash icon
- [ ] Tap on card to see detailed view
- [ ] Verify Dutch date formatting works

### 2. **Toevoegen Tab (Add Data)**

#### Add Food Entry:
- [ ] Select each category: Drinken, Ontbijt, Lunch, Diner, Snack
- [ ] Enter description (e.g., "Yoghurt met granola")
- [ ] Add ingredients separated by commas (e.g., "Yoghurt, Melk, Granola")
- [ ] Choose date/time
- [ ] Add optional notes
- [ ] Submit and verify it appears in Dagboek

#### Add Health Metrics:
- [ ] Move sliders for all metrics (0-10):
  - Eczeem Ernst (eczema severity)
  - Eczeem Jeuk (eczema itching)
  - Energie Niveau (energy level)
  - Slaap Kwaliteit (sleep quality)
  - Stress Niveau (stress level)
- [ ] Choose date/time
- [ ] Add optional notes
- [ ] Submit and verify it appears in Dagboek

### 3. **Analyse Tab (AI Analysis)** ⭐ NEW

#### Period Selection:
- [ ] Test "Alles" (All data)
- [ ] Test "Week" (Last 7 days)
- [ ] Test "Maand" (Last 30 days)

#### AI Analysis:
- [ ] Click "Start AI Analyse" button
- [ ] Wait for loading indicator (1.5 seconds)
- [ ] Verify results sections:

**Eczeem Overzicht:**
- [ ] Average eczema level displayed
- [ ] Visual indicators for severity
- [ ] Day count shown

**Gevonden Patronen (Patterns):**
- [ ] Lists frequent ingredients
- [ ] Shows eczema severity patterns
- [ ] Displays confidence scores

**Correlaties (Correlations):**
- [ ] Tests for known allergens (Melk, Gluten, Noten, Eieren)
- [ ] Shows percentage differences
- [ ] Displays warnings for triggers (≥40% impact)
- [ ] Example: "Melk verergert eczeem (6.2/10 vs 2.1/10, +52%)"

**Aanbevelingen (Recommendations):**
- [ ] Suggests avoiding triggers
- [ ] Highlights positive foods
- [ ] General health advice

**Grafieken (Charts):**
- [ ] Day view: Daily eczema vs allergen intake
- [ ] Week view: Weekly averages
- [ ] Month view: Monthly trends
- [ ] Interactive tooltips on hover

### 4. **Sample Data Testing**

The app comes with 13 days of sample data pre-loaded:
- [ ] Verify sample data loads automatically
- [ ] Check for realistic eczema-milk correlations in data
- [ ] Days with milk: Higher eczema (4-7/10)
- [ ] Days without milk: Lower eczema (1-3/10)

### 5. **Data Persistence**

- [ ] Add new entries
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify all data persists (SharedPreferences)

## 🐛 Known Issues to Test

### Expected to Work:
✅ Week number calculation (FIXED)
✅ Analysis screen navigation (FIXED)
✅ Dutch date formatting
✅ State management (Provider)
✅ JSON serialization
✅ Local storage

### Potential Issues to Watch For:
⚠️ If data doesn't persist, check SharedPreferences permissions
⚠️ Charts might not display on first render (requires data)
⚠️ Long ingredient lists might overflow UI

## 📊 Expected AI Analysis Results

With the sample data, you should see:

### Patterns:
- "📊 Gemiddelde eczeem niveau: 3.5/10" (or similar)
- "🍽️ Frequent: Melk (8x)"
- "🍽️ Frequent: Haver (6x)"

### Correlations:
- "⚠️ Waarschuwing: Melk verergert eczeem"
  - Should show ~40-60% increase when milk is consumed
  - Correlation strength: 0.4-0.6

### Recommendations:
- "⚠️ Overweeg 'Melk' te vermijden"
- "✅ '[Safe food]' helpt met je eczeem"

## 🎯 Success Criteria

The app is working correctly if:
1. ✅ No compilation errors
2. ✅ All three tabs accessible via navigation
3. ✅ Can add/delete entries
4. ✅ AI analysis runs without crashes
5. ✅ Milk correlation detected with ≥40% threshold
6. ✅ Charts display with data points
7. ✅ Data persists after app restart
8. ✅ Dutch language displays correctly

## 🛠️ Troubleshooting

### "Flutter not found"
```powershell
# Check if Flutter is installed
flutter --version

# If not, download from: https://docs.flutter.dev/get-started/install
```

### "No devices found"
```powershell
# Enable Chrome
flutter config --enable-web

# Or enable Windows desktop
flutter config --enable-windows-desktop
```

### "Dependencies error"
```powershell
flutter clean
flutter pub get
```

### "Hot reload not working"
```powershell
# Full restart
flutter run
# Then press 'R' in terminal for hot restart
```

## 📝 Test Reporting

When testing, note:
- Device/platform tested on
- Flutter version (`flutter --version`)
- Any error messages
- UI/UX issues
- Performance observations
- Data accuracy issues

## 🎨 UI Elements to Verify

- [ ] Material Design 3 components render correctly
- [ ] Bottom navigation works smoothly
- [ ] Cards and lists are readable
- [ ] Sliders are responsive
- [ ] Date pickers show Dutch locale
- [ ] Colors match categories:
  - 🔵 Blauw = Drinken
  - 🟠 Oranje = Ontbijt
  - 🟡 Amber = Lunch
  - 🟣 Purple = Diner
  - 🟢 Groen = Snack

## 📱 Next Steps After Testing

1. Report any bugs found
2. Test on multiple devices/platforms
3. Add more real-world data
4. Evaluate AI accuracy with personal data
5. Consider additional features:
   - Data export (CSV/JSON)
   - Dark mode
   - Cloud sync
   - Photo attachments
   - Search functionality

---

**Last Updated:** 2026-01-24
**Fixed Issues:** getWeekNumber() function, Analyse screen navigation
**Status:** Ready for testing ✅
