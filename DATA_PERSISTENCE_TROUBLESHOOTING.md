# 🔧 Data Persistence Troubleshooting Guide

## Problem: Data Changes Are Not Being Saved

If you're experiencing issues where your data changes disappear after restarting the app, follow this guide.

---

## ✅ Quick Checks

### 1. Are You in Incognito/Private Mode?

**Problem:** SharedPreferences (localStorage) doesn't work in private/incognito browser mode.

**Solution:**
- Open the app in a **regular browser window** (not incognito)
- Data will only persist in normal browsing mode

### 2. Check Browser Console for Save Logs

**How to check:**
1. Press `F12` to open Developer Tools
2. Go to the **Console** tab
3. Look for these messages:

```
=== OPSLAAN IN OPSLAG ===
Key: dagboek_entries
Entries: 13
Data size: 12345 chars
✅ Data opgeslagen
```

**If you see ❌ errors:**
- There's a problem with data serialization or storage
- Check the error message for details

### 3. Verify Data is Actually Stored

**Check localStorage directly:**
1. Open Developer Tools (`F12`)
2. Go to **Console** tab
3. Type this command:

```javascript
localStorage.getItem('flutter.dagboek_entries')
```

4. Press Enter

**Expected result:**
- You should see a long JSON string with your data
- If it returns `null`, data is not being saved

### 4. Check if Data Loads on Startup

**Look for this in Console on app start:**

```
=== LADEN VAN OPSLAG ===
Key: dagboek_entries  
Data gevonden: JA (12345 chars)
13 entries geladen
```

**If you see:**
- `Data gevonden: NEE` - Data was not saved previously
- `Geen opgeslagen data gevonden` - No saved data found

---

## 🐛 Common Issues & Solutions

### Issue 1: Data Saves But Doesn't Load

**Symptoms:**
- Console shows "✅ Data opgeslagen"
- But next time app starts, sample data loads again

**Possible causes:**
1. Browser is clearing localStorage
2. Different localStorage key being used
3. App is in different domain/port

**Solution:**
```javascript
// Check what's actually in localStorage
console.log(Object.keys(localStorage));

// Look for keys starting with 'flutter.'
```

### Issue 2: "Eerste keer opstarten" Every Time

**Symptoms:**
- Console always shows "Eerste keer opstarten - laden sample data"
- Data never persists between sessions

**Cause:** Initialization flag not being saved

**Solution:**
1. Check browser localStorage settings
2. Make sure cookies/storage is allowed for localhost
3. Try a different browser

### Issue 3: Data Disappears After Hot Reload

**This is NORMAL behavior!**

During development with Flutter hot reload (`r` key):
- The provider might reinitialize
- But data should reload from localStorage automatically

**To test persistence properly:**
1. Make a change in the app
2. Close the browser tab completely
3. Re-run `start_app.bat`
4. Check if your changes are still there

### Issue 4: Can't Edit Existing Entries

**Current limitation:**
- The detail view is **read-only**
- You can only **add new entries** or **delete entries**
- No edit functionality is currently implemented

**Workaround:**
1. Delete the entry you want to change
2. Add a new entry with the correct data

---

## 🧪 Testing Data Persistence

### Step-by-Step Test:

1. **Add a test entry:**
   - Go to "Toevoegen" tab
   - Add a unique food item (e.g., "TEST ITEM")
   - Click save

2. **Verify it's saved:**
   - Open Console (`F12`)
   - Look for "✅ Data opgeslagen" message
   - Run: `localStorage.getItem('flutter.dagboek_entries')`
   - Search for "TEST ITEM" in the output

3. **Close and reopen:**
   - Close the browser tab completely
   - Stop the app (`Ctrl+C` in the terminal)
   - Run `start_app.bat` again
   - Check if "TEST ITEM" is still in the Dagboek

4. **Check console on startup:**
   - Look for "=== LADEN VAN OPSLAG ==="
   - Should show "Data gevonden: JA"

---

## 🔍 Debug Mode

### Enable Detailed Logging

The app now includes detailed logging. Check the console for:

**When adding data:**
```
✅ Voedsel toegevoegd en opgeslagen
=== OPSLAAN IN OPSLAG ===
...
```

**On app startup:**
```
=== LADEN VAN OPSLAG ===
Key: dagboek_entries
Data gevonden: JA (...)
X entries geladen
```

### Manual Data Check

**View all saved data:**
```javascript
// In browser console
const data = JSON.parse(localStorage.getItem('flutter.dagboek_entries'));
console.table(data);
```

**Check how many entries:**
```javascript
const data = JSON.parse(localStorage.getItem('flutter.dagboek_entries'));
console.log(`Entries saved: ${data ? data.length : 0}`);
```

**Clear all data (reset):**
```javascript
localStorage.clear();
location.reload();
```

---

## 🛠️ Advanced Troubleshooting

### Check SharedPreferences Key

The app uses this key:
```dart
static const String _storageKey = 'dagboek_entries';
```

But Flutter Web might prefix it with `'flutter.'`, so the actual key is:
```
flutter.dagboek_entries
```

### Verify in Different Browser

Try these browsers to isolate the issue:
- ✅ Chrome
- ✅ Edge
- ✅ Firefox

### Check Browser Settings

Ensure these are enabled:
- ☑️ Cookies allowed for localhost
- ☑️ Site data/localStorage allowed
- ☑️ Not in private/incognito mode

### Clear Cache and Try Again

Sometimes browser cache causes issues:

1. Open Developer Tools (`F12`)
2. Right-click the refresh button
3. Select "Empty Cache and Hard Reload"
4. Or: Settings → Clear browsing data → Cached images and files

---

## 📋 Checklist for Data Persistence

Before reporting an issue, verify:

- [ ] Not in incognito/private mode
- [ ] Console shows "✅ Data opgeslagen" after adding data
- [ ] localStorage.getItem shows the data
- [ ] Console shows data loading on app restart
- [ ] Tried closing browser completely and restarting
- [ ] Checked in different browser
- [ ] Browser allows localStorage for localhost

---

## 🚀 If Everything Fails

### Option 1: Reset Everything

```javascript
// In browser console
localStorage.clear();
sessionStorage.clear();
location.reload();
```

### Option 2: Build and Run Release Version

```bash
# Stop the debug app
# Build release version
flutter build web --release

# Serve the release build
cd build/web
python -m http.server 8080
```

Then open `http://localhost:8080` and test persistence.

### Option 3: Export/Import Data (Future Feature)

Currently not implemented, but you can manually backup:

```javascript
// Backup data
const backup = localStorage.getItem('flutter.dagboek_entries');
console.log(backup);  // Copy this
```

```javascript
// Restore data
const backup = '...paste here...';
localStorage.setItem('flutter.dagboek_entries', backup);
location.reload();
```

---

## 📞 Still Having Issues?

Check:
1. `README.md` - General app documentation
2. `DATA_MANAGEMENT_GUIDE.md` - How to manage data
3. `VSCODE_SETUP.md` - Development setup

**Console logs are your friend!** Always check the browser console (`F12`) for error messages and save confirmations.
