# 🔧 Hoe de Verbeterde AI Algoritme Te Gebruiken

## ✅ **Quick Answer**

**Vraag:** Werkt het algoritme met meerdere allergenen?

**Antwoord:** 
- ❌ **Huidige versie**: Gedeeltelijk - heeft problemen met meerdere allergenen tegelijk
- ✅ **Verbeterde versie**: JA - handelt meerdere allergenen correct!

---

## 📋 **Wat Je Moet Weten**

### **Het Probleem:**
Het huidige algoritme vergelijkt:
- "Dagen MET Melk" vs "Dagen ZONDER Melk"

Maar als iemand ook Gluten-allergisch is:
- Dagen "zonder Melk" bevatten WEL Gluten!
- Dit vertekent de resultaten

### **De Oplossing:**
Nieuw algoritme vergelijkt:
- "Dagen MET Melk" vs "Dagen ZONDER ENKEL ALLERGEN"
- Detecteert combinatie-effecten
- Geeft extra informatie

---

## 🚀 **Optie 1: Quick Fix (Snelste)**

### **Stap 1: Open de huidige service**
```
C:\Down\orions2\GezondheidsTrackerFlutter\lib\services\ai_analyse_service.dart
```

### **Stap 2: Vervang de functie**

Zoek deze functie (rond regel 100):
```dart
List<Correlatie> _berekenEczeemCorrelaties(List<DagboekEntry> entries)
```

Vervang de **hele functie** met de verbeterde versie uit:
```
ai_analyse_service_improved.dart
```

Kopieer:
1. `_berekenEczeemCorrelatiesVerbeterd` functie
2. `_checkCombinatieEffecten` functie

### **Stap 3: Update de aanroep**

In `analyseerData` functie, verander:
```dart
// OUD:
final correlaties = _berekenEczeemCorrelaties(dagboekEntries);

// NIEUW:
final correlaties = _berekenEczeemCorrelatiesVerbeterd(dagboekEntries);
```

### **Stap 4: Test**
```bash
flutter run
```

---

## 🔄 **Optie 2: Volledige Vervanging (Schoner)**

### **Stap 1: Backup huidige versie**
```bash
# In terminal
cd lib/services
copy ai_analyse_service.dart ai_analyse_service_backup.dart
```

### **Stap 2: Vervang het bestand**

Kopieer de verbeterde code van:
- `ai_analyse_service_improved.dart`

Naar:
- `ai_analyse_service.dart`

### **Stap 3: Hernoem de class**
In het nieuwe bestand, wijzig:
```dart
// OUD:
class AIAnalyseServiceImproved {

// NIEUW:
class AIAnalyseService {
```

### **Stap 4: Test**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 **Wat Verandert Er?**

### **Oude Output:**
```
⚠️ Waarschuwing: Melk verergert eczeem (7.0/10 vs 4.5/10, +56%)
⚠️ Waarschuwing: Gluten verergert eczeem (7.5/10 vs 4.0/10, +88%)
```

**Probleem:** Percentages zijn vertekend!

### **Nieuwe Output:**
```
⚠️ Waarschuwing: Melk verergert eczeem (6.0/10 vs 2.0/10, +200%) [5x alleen]
⚠️ Waarschuwing: Gluten verergert eczeem (7.0/10 vs 2.0/10, +250%) [3x alleen]
⚠️ COMBINATIE-EFFECT: Melk + Gluten samen erger (9.0/10 vs 6.5/10 apart)
```

**Voordeel:** 
- ✅ Accurate percentages
- ✅ Extra context ("[Xx alleen]")
- ✅ Combinatie-effecten gedetecteerd

---

## 🧪 **Test de Verbeteringen**

### **Test Data Set 1: Enkel Allergen**

Voeg toe in app:
```
Dag 1-5: Melk → Eczeem 7/10
Dag 6-10: Geen allergenen → Eczeem 2/10
```

**Verwachte Output:**
```
Melk verergert eczeem (7.0/10 vs 2.0/10, +250%) [5x alleen]
```

---

### **Test Data Set 2: Twee Allergenen**

Voeg toe in app:
```
Dag 1-3: Alleen Melk → Eczeem 6/10
Dag 4-6: Alleen Gluten → Eczeem 7/10
Dag 7-10: Geen allergenen → Eczeem 2/10
```

**Oude Algoritme (FOUT):**
```
Melk: +33%  ❌ (te laag)
Gluten: +75%  ❌ (te laag)
```

**Nieuwe Algoritme (CORRECT):**
```
Melk: +200% [3x alleen] ✅
Gluten: +250% [3x alleen] ✅
```

---

### **Test Data Set 3: Combinatie**

Voeg toe in app:
```
Dag 1-2: Alleen Melk → Eczeem 5/10
Dag 3-4: Alleen Gluten → Eczeem 6/10
Dag 5-7: Melk + Gluten → Eczeem 9/10
Dag 8-10: Geen allergenen → Eczeem 2/10
```

**Oude Algoritme:**
- Mist combinatie-effect ❌

**Nieuwe Algoritme:**
```
Melk: +150% [2x alleen] ✅
Gluten: +200% [2x alleen] ✅
COMBINATIE: Melk + Gluten samen erger (+3.5 extra!) ✅
```

---

## ⚠️ **Belangrijke Notities**

### **Minimum Data Vereisten:**

**Voor betrouwbare analyse met NIEUWE algoritme:**
- Minimaal 3-4 "schone" dagen (zonder allergenen)
- Minimaal 2 dagen MET elk allergen
- Bij voorkeur enkele dagen met allergen alleen

**Als je NIET genoeg schone dagen hebt:**
- Algoritme kan geen baseline bepalen
- Resultaten zijn minder betrouwbaar
- Advies: verzamel meer variatie in data

### **Vals-Positieven Nog Steeds Mogelijk:**

Als iemand:
- Altijd Melk + Brood eet (samen)
- NOOIT Brood zonder Melk
- Alleen allergisch voor Melk

**Resultaat:**
```
Melk: +250% [altijd in combinatie] ⚠️
Gluten: +250% [altijd in combinatie] ⚠️ MOGELIJK VALS POSITIEF!
```

**Hoe te interpreteren:**
- "[altijd in combinatie]" = waarschuwing
- Kan vals positief zijn
- Test allergenen apart voor bevestiging

---

## 💡 **Best Practices voor Gebruikers**

### **1. Varieer je Voedsel**
```
✅ GOED:
Dag 1: Melk + Brood
Dag 2: Alleen Melk
Dag 3: Alleen Brood
Dag 4: Geen allergenen

❌ SLECHT:
Dag 1: Melk + Brood
Dag 2: Melk + Brood
Dag 3: Melk + Brood
Dag 4: Melk + Brood
```

### **2. Plan "Schone" Dagen**
Probeer elke week 1-2 dagen met:
- Geen melk
- Geen gluten
- Geen noten
- Geen eieren

### **3. Test Verdachte Allergenen Systematisch**
```
Week 1: Normale dieet (variatie)
Week 2: Vermijd Melk (test baseline)
Week 3: Alleen Melk testen
Week 4: Alleen Gluten testen
```

---

## 🎯 **Wanneer Gebruik Welk Algoritme?**

### **Gebruik OUDE versie als:**
- ❌ Niet aanbevolen
- Alleen voor vergelijking met oude data

### **Gebruik NIEUWE versie als:**
- ✅ Meerdere allergenen mogelijk
- ✅ Wil accurate percentages
- ✅ Wil combinatie-effecten detecteren
- ✅ Heeft variatie in data

---

## 📚 **Referentie Bestanden**

| Bestand | Beschrijving |
|---------|--------------|
| `ai_analyse_service.dart` | Huidige implementatie (PROBLEMATISCH) |
| `ai_analyse_service_improved.dart` | Verbeterde versie (AANBEVOLEN) |
| `ALGORITHM_ANALYSIS.md` | Gedetailleerde technische analyse |
| `HOW_TO_USE_IMPROVED_ALGORITHM.md` | Deze gids |

---

## 🔧 **Troubleshooting**

### **Probleem: "Niet genoeg schone dagen"**

**Symptoom:**
```
Geen correlaties gevonden
Of: Zeer lage percentages
```

**Oplossing:**
- Verzamel meer data
- Plan specifiek "schone" dagen
- Minimaal 3-4 dagen zonder allergenen

---

### **Probleem: "Te veel vals-positieven"**

**Symptoom:**
```
Alle voedsel lijkt allergen
Onlogische correlaties
```

**Oplossing:**
- Check for "[altijd in combinatie]" tag
- Test allergenen apart
- Verhoog drempelwaarde in code:

```dart
// In _berekenEczeemCorrelatiesVerbeterd
// Verander van 40% naar 50% of 60%
if (percentageVerschil >= 50 && verschil > 0) {  // Was 40
```

---

### **Probleem: "Combinaties worden niet gedetecteerd"**

**Symptoom:**
```
Alleen individuele allergenen
Geen "COMBINATIE-EFFECT" bericht
```

**Oplossing:**
- Verzamel meer data met combinaties
- Minimaal 2 dagen met combinatie
- Minimaal 1 dag met elk allergen apart

---

## ✅ **Checklist voor Implementatie**

- [ ] Backup gemaakt van huidige versie
- [ ] Verbeterde functie gekopieerd
- [ ] Functienaam aangepast in aanroep
- [ ] Code compileert zonder errors
- [ ] App getest in simulator/device
- [ ] Test data toegevoegd
- [ ] Output geverifieerd (nieuwe format)
- [ ] Oude backup verwijderd (na succes)

---

## 🎉 **Klaar!**

Je hebt nu een algoritme dat:
- ✅ Meerdere allergenen correct detecteert
- ✅ Accurate percentages berekent
- ✅ Combinatie-effecten vindt
- ✅ Extra context geeft
- ✅ Vals-positieven vermindert

**Happy tracking! 🏥**

---

**Vragen?** Check `ALGORITHM_ANALYSIS.md` voor technische details!
