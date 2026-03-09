# 📊 Data Management Guide - Hoe Data Te Benaderen & Wijzigen

**Datum:** 2026-01-24  
**Voor:** Testen van het verbeterde AI algoritme

---

## 📍 **Waar Staat de Data?**

### **1. Data Opslag Locatie**

**Tijdens Development/Testing:**
- Data wordt opgeslagen in **SharedPreferences** (lokale browser storage)
- Voor Chrome: `localStorage` in de browser
- Data blijft behouden tussen app restarts

**Key naam:** `dagboek_entries`

**Bestand:** `lib/providers/dagboek_provider.dart`

---

## 🔍 **Hoe Data Wordt Geladen**

### **Bij App Start:**

```dart
// lib/providers/dagboek_provider.dart

DagboekProvider() {
  _laadData();  // → Wordt automatisch aangeroepen
}

Future<void> _laadData() async {
  await _laadVanOpslag();           // Laad van SharedPreferences
  if (_dagboekEntries.isEmpty) {    // Als leeg:
    _laadVoorbeeldData();           // → Laad sample data
    await _slaOpInOpslag();         // → Sla op
  }
  notifyListeners();
}
```

**Flow:**
1. App start
2. Probeer data te laden van SharedPreferences
3. Als geen data → laad voorbeeld data
4. Sla op in SharedPreferences

---

## 📝 **Hoe Data Te Wijzigen**

### **Methode 1: Via de App UI (Aanbevolen voor Testing)**

**A. Voeg Voedsel Toe:**
1. Open app in VS Code (F5 of Run → Start Debugging)
2. Ga naar **"Toevoegen"** tab
3. Vul formulier in:
   - Selecteer categorie (Ontbijt, Lunch, Diner, Snack)
   - Voeg beschrijving toe
   - **Belangrijk:** Selecteer ingrediënten
   - Kies datum (voor het testen van verschillende scenario's)
4. Klik "Voeg Toe"

**B. Voeg Gezondheidsdata Toe:**
1. Ga naar **"Toevoegen"** tab
2. Scroll naar "Gezondheidsinformatie"
3. Stel sliders in:
   - **Eczeem Ernst** (0-10)
   - **Eczeem Jeuk** (0-10)
   - Energie Niveau
   - Slaap Kwaliteit
   - Stress Niveau
4. Kies datum
5. Klik "Registreer Gezondheid"

---

### **Methode 2: Data Resetten (Schone Start)**

**In de Browser Console (F12):**

```javascript
// Open Developer Tools (F12)
// Ga naar Console tab
// Voer uit:

localStorage.clear();
// Dan herlaad de app (F5)
```

**Of via de app:**
Voeg deze functie toe in `dagboek_provider.dart`:

```dart
// Voeg toe in DagboekProvider class
Future<void> resetAlleData() async {
  _dagboekEntries.clear();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_storageKey);
  _laadVoorbeeldData();
  await _slaOpInOpslag();
  notifyListeners();
}
```

---

### **Methode 3: Sample Data Aanpassen (Voor Specifieke Tests)**

**Bewerk:** `lib/providers/dagboek_provider.dart`

**Zoek functie:** `_laadVoorbeeldData()` (regel ~199)

**Voorbeeld aanpassing voor test met meerdere allergenen:**

```dart
void _laadVoorbeeldData() {
  final vandaag = DateTime.now();

  // TEST SCENARIO: Twee allergenen (Melk & Gluten)
  
  // Week 1: Dagen met ALLEEN Melk
  for (int i = 10; i >= 8; i--) {
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag.subtract(Duration(days: i)),
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Yoghurt met fruit",
          ingredienten: ["Yoghurt", "Banaan"], // Melk, geen Gluten!
        ),
      ],
      gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 6,  // Hoog door Melk
          eczeemJeuken: 6,
          energieNiveau: 5,
          slaapKwaliteit: 6,
          stressNiveau: 4,
        ),
      ],
    ));
  }

  // Week 2: Dagen met ALLEEN Gluten
  for (int i = 7; i >= 5; i--) {
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag.subtract(Duration(days: i)),
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Toast zonder melk",
          ingredienten: ["Brood", "Jam"], // Gluten, geen Melk!
        ),
      ],
      gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 7,  // Hoog door Gluten
          eczeemJeuken: 7,
          energieNiveau: 4,
          slaapKwaliteit: 5,
          stressNiveau: 5,
        ),
      ],
    ));
  }

  // Week 3: Dagen met BEIDE (Melk + Gluten)
  for (int i = 4; i >= 2; i--) {
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag.subtract(Duration(days: i)),
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Pannenkoeken met melk",
          ingredienten: ["Pannenkoeken", "Melk", "Boter"], // BEIDE!
        ),
      ],
      gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 9,  // ZEER HOOG door combinatie!
          eczeemJeuken: 9,
          energieNiveau: 3,
          slaapKwaliteit: 4,
          stressNiveau: 7,
        ),
      ],
    ));
  }

  // Week 4: "Schone" dagen (GEEN allergenen)
  for (int i = 1; i >= 0; i--) {
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag.subtract(Duration(days: i)),
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Fruit en noten",
          ingredienten: ["Appel", "Noten"], // Geen bekende allergenen
        ),
      ],
      gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 2,  // LAAG!
          eczeemJeuken: 2,
          energieNiveau: 8,
          slaapKwaliteit: 8,
          stressNiveau: 2,
        ),
      ],
    ));
  }

  _sorteerdagboekEntries();
}
```

**Na aanpassing:**
1. Sla bestand op
2. Reset data (localStorage.clear() in console)
3. Herlaad app (F5)
4. Nieuwe sample data wordt geladen!

---

## 🧪 **Test Scenarios**

### **Scenario A: Test Enkel Allergen**

**Doel:** Verifieer dat algoritme 1 allergen correct detecteert

**Data setup:**
- 5 dagen met Melk → Eczeem 7/10
- 5 dagen zonder Melk → Eczeem 2/10

**Verwachte output:**
```
⚠️ Melk verergert eczeem (7.0/10 vs 2.0/10, +250%) [5x alleen]
```

**Hoe te maken:**
```dart
// In _laadVoorbeeldData()

// 5 dagen MET melk
for (int i = 9; i >= 5; i--) {
  _dagboekEntries.add(DagboekEntry(
    datum: vandaag.subtract(Duration(days: i)),
    voedselEntries: [
      VoedselEntry(
        categorie: VoedselCategorie.ontbijt,
        beschrijving: "Yoghurt",
        ingredienten: ["Yoghurt", "Fruit"],
      ),
    ],
    gezondheidsMetrics: [
      GezondheidsMetric(
        eczeemErnstig: 7,
        eczeemJeuken: 7,
        energieNiveau: 5,
        slaapKwaliteit: 6,
        stressNiveau: 4,
      ),
    ],
  ));
}

// 5 dagen ZONDER melk
for (int i = 4; i >= 0; i--) {
  _dagboekEntries.add(DagboekEntry(
    datum: vandaag.subtract(Duration(days: i)),
    voedselEntries: [
      VoedselEntry(
        categorie: VoedselCategorie.ontbijt,
        beschrijving: "Fruit",
        ingredienten: ["Appel", "Banaan"],
      ),
    ],
    gezondheidsMetrics: [
      GezondheidsMetric(
        eczeemErnstig: 2,
        eczeemJeuken: 2,
        energieNiveau: 8,
        slaapKwaliteit: 8,
        stressNiveau: 2,
      ),
    ],
  ));
}
```

---

### **Scenario B: Test Meerdere Allergenen**

**Doel:** Verifieer dat algoritme Melk en Gluten apart kan identificeren

**Data setup:**
- 3 dagen ALLEEN Melk → Eczeem 6/10
- 3 dagen ALLEEN Gluten → Eczeem 7/10
- 3 dagen GEEN allergenen → Eczeem 2/10

**Verwachte output:**
```
⚠️ Melk verergert eczeem (6.0/10 vs 2.0/10, +200%) [3x alleen]
⚠️ Gluten verergert eczeem (7.0/10 vs 2.0/10, +250%) [3x alleen]
```

---

### **Scenario C: Test Combinatie-Effect**

**Doel:** Verifieer dat algoritme synergistische effecten detecteert

**Data setup:**
- 2 dagen ALLEEN Melk → Eczeem 5/10
- 2 dagen ALLEEN Gluten → Eczeem 6/10
- 3 dagen Melk + Gluten → Eczeem 9/10
- 3 dagen GEEN allergenen → Eczeem 2/10

**Verwachte output:**
```
⚠️ Melk verergert eczeem (7.0/10 vs 2.0/10, +250%) [2x alleen]
⚠️ Gluten verergert eczeem (7.5/10 vs 2.0/10, +275%) [2x alleen]
⚠️ COMBINATIE-EFFECT: Melk + Gluten samen erger (9.0/10 vs 5.5/10 apart)
```

---

## 🔍 **Data Inspecteren**

### **Methode 1: Via Browser Developer Tools**

```javascript
// Open Console (F12)
// Bekijk opgeslagen data:

JSON.parse(localStorage.getItem('flutter.dagboek_entries'))
```

**Output:** Array met alle dagboek entries

---

### **Methode 2: Via App UI**

1. Ga naar **"Dagboek"** tab
2. Bekijk lijst van alle entries
3. Klik op entry voor details

---

### **Methode 3: Via Debug Print**

Voeg toe in `dagboek_provider.dart`:

```dart
void debugPrintData() {
  print('=== DAGBOEK DATA ===');
  for (var entry in _dagboekEntries) {
    print('Datum: ${entry.datumFormatted}');
    print('  Voedsel: ${entry.voedselEntries.map((v) => v.ingredienten).join(", ")}');
    print('  Eczeem: ${entry.gezondheidsMetrics.isNotEmpty ? entry.gezondheidsMetrics.first.eczeemErnstig : "N/A"}');
  }
  print('===================');
}
```

Roep aan:
```dart
// In analyseer() functie, voor de analyse
debugPrintData();
```

---

## 🎯 **Welke Ingrediënten Worden Gedetecteerd?**

**In:** `lib/services/ai_analyse_service.dart`

```dart
// Regel ~107
final knownAllergens = {
  'Melk': ['Melk', 'Yoghurt', 'Kaas', 'Boter', 'Honing'],
  'Gluten': ['Brood', 'Pasta', 'Toast', 'Pannenkoeken'],
  'Noten': ['Noten', 'Pindas'],
  'Eieren': ['Ei'],
};
```

**⚠️ Belangrijk:**
- Alleen deze ingrediënten worden getest!
- Gebruik EXACT deze namen in je voedsel entries
- Hoofdlettergevoelig: "Melk" ✅, "melk" ❌

---

## 📋 **Ingredient Checklist**

### **Voor Melk Tests:**
✅ Gebruik: `Melk`, `Yoghurt`, `Kaas`, `Boter`, `Honing`
❌ Vermijd: andere ingrediënten

### **Voor Gluten Tests:**
✅ Gebruik: `Brood`, `Pasta`, `Toast`, `Pannenkoeken`
❌ Vermijd: andere ingrediënten

### **Voor Noten Tests:**
✅ Gebruik: `Noten`, `Pindas`
❌ Vermijd: andere ingrediënten

### **Voor Eieren Tests:**
✅ Gebruik: `Ei`
❌ Vermijd: andere ingrediënten

### **Voor "Schone" Dagen:**
✅ Gebruik: `Appel`, `Banaan`, `Kip`, `Rijst`, `Broccoli`, etc.
❌ Vermijd: bovenstaande allergenen

---

## 🚀 **Quick Test Guide**

### **Stap 1: Reset Data**
```javascript
// Browser Console (F12)
localStorage.clear();
```

### **Stap 2: Pas Sample Data Aan**
Edit `lib/providers/dagboek_provider.dart` → `_laadVoorbeeldData()`

### **Stap 3: Herstart App**
```bash
# In VS Code:
# Stop app (Shift+F5)
# Start app (F5)
```

### **Stap 4: Test Analyse**
1. Ga naar "Analyse" tab
2. Klik "Start AI Analyse"
3. Bekijk resultaten

### **Stap 5: Verifieer Output**
Check of je ziet:
- ✅ Correcte percentages
- ✅ "[Xx alleen]" of "[altijd in combinatie]"
- ✅ Mogelijk combinatie-effecten

---

## 💾 **Data Persistentie**

### **Data Blijft Behouden:**
- ✅ Tussen app restarts
- ✅ Na browser refresh (F5)
- ✅ Na VS Code restart

### **Data Wordt Verwijderd:**
- ❌ Na `localStorage.clear()`
- ❌ Bij browser cache wissen
- ❌ Bij browser private mode

---

## 🔧 **Troubleshooting**

### **Probleem: Sample data laadt niet**

**Oplossing:**
1. Check browser console (F12) voor errors
2. Clear localStorage: `localStorage.clear()`
3. Herlaad app (F5)

---

### **Probleem: Analyse toont geen correlaties**

**Mogelijke oorzaken:**
1. **Te weinig data** - minimum 2 dagen per allergen nodig
2. **Geen schone dagen** - minstens 1 dag zonder allergenen nodig
3. **Verkeerde ingrediënten** - gebruik exact de namen uit `knownAllergens`
4. **Te lage drempel** - verschil moet >40% zijn

**Check:**
```dart
// In ai_analyse_service.dart, regel ~174
if (percentageVerschil >= 40 && verschil > 0) {
  // ^^^ Drempelwaarde
```

---

### **Probleem: Data verdwijnt**

**Oplossing:**
- Check of je niet in private/incognito mode werkt
- SharedPreferences werkt niet in private mode

---

## 📊 **Data Structure Reference**

```dart
DagboekEntry {
  DateTime datum;
  List<VoedselEntry> voedselEntries;
  List<GezondheidsMetric> gezondheidsMetrics;
}

VoedselEntry {
  VoedselCategorie categorie;  // ontbijt, lunch, diner, snack
  String beschrijving;
  List<String> ingredienten;   // BELANGRIJK voor AI
  String? notities;
  DateTime tijdstip;
}

GezondheidsMetric {
  int eczeemErnstig;    // 0-10, BELANGRIJK voor AI
  int eczeemJeuken;     // 0-10, BELANGRIJK voor AI
  int energieNiveau;    // 0-10
  int slaapKwaliteit;   // 0-10
  int stressNiveau;     // 0-10
  String? notities;
  DateTime tijdstip;
}
```

---

## ✅ **Best Practices**

### **Voor Accurate Testing:**

1. ✅ **Gebruik consistente ingrediëntnamen**
   - Exact zoals in `knownAllergens` gedefinieerd

2. ✅ **Creëer voldoende "schone" dagen**
   - Minimaal 3-4 dagen zonder allergenen

3. ✅ **Test allergenen ook apart**
   - Maak dagen met ALLEEN Melk, ALLEEN Gluten, etc.

4. ✅ **Gebruik realistische eczeem scores**
   - Met allergen: 6-9/10
   - Zonder allergen: 1-3/10
   - Combinatie: 8-10/10

5. ✅ **Verzamel genoeg data**
   - Minimum 10 dagen totaal
   - Minimum 2 dagen per allergen

---

**Je bent nu klaar om de data te benaderen en wijzigen voor testing! 🚀**

Voor vragen, check de andere documentatie:
- `IMPLEMENTATION_COMPLETE.md` - Wat is er veranderd
- `ALGORITHM_ANALYSIS.md` - Hoe het algoritme werkt
- `VSCODE_SETUP.md` - Hoe de app te runnen
