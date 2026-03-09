# 🚀 How to Start GezondheidsTracker from Visual Studio Code

## 📋 Prerequisites

Before you begin, you need:

### 1. **Flutter SDK Installed**
If not already installed:
- Download from: https://docs.flutter.dev/get-started/install/windows
- Or use winget: `winget install Google.Flutter`
- Add to PATH: `C:\flutter\bin` (or wherever you installed it)

### 2. **Visual Studio Code**
Download from: https://code.visualstudio.com/

### 3. **VS Code Extensions** (Required)
Install these two extensions in VS Code:
- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)

---

## ⚙️ Step 1: Install VS Code Extensions

1. Open Visual Studio Code
2. Click the Extensions icon in the left sidebar (or press `Ctrl+Shift+X`)
3. Search for "Flutter"
4. Click **Install** on "Flutter" by Dart Code
   - This will automatically install the Dart extension too
5. Wait for installation to complete

**Verify:** You should see "Flutter" and "Dart" in your installed extensions list.

---

## 📂 Step 2: Open Project in VS Code

### Method 1: Open Folder
1. In VS Code, go to **File > Open Folder**
2. Navigate to: `C:\Down\orions2\GezondheidsTrackerFlutter`
3. Click **Select Folder**

### Method 2: From File Explorer
1. Navigate to `C:\Down\orions2\GezondheidsTrackerFlutter` in File Explorer
2. Right-click in the folder
3. Select **Open with Code**

**Verify:** You should see the project structure in VS Code's Explorer sidebar with folders like `lib`, `android`, `ios`, etc.

---

## 🔧 Step 3: Get Flutter Dependencies

1. Open the **Terminal** in VS Code:
   - Menu: **Terminal > New Terminal**
   - Or press: `` Ctrl+` `` (backtick)

2. Run this command:
```bash
flutter pub get
```

3. Wait for it to complete. You should see:
```
Running "flutter pub get" in GezondheidsTrackerFlutter...
Resolving dependencies...
Got dependencies!
```

**What this does:** Downloads all required packages (provider, intl, fl_chart, etc.)

---

## 🎯 Step 4: Select a Device/Platform

VS Code needs to know where to run your app. You have several options:

### **Option A: Chrome (Recommended - Easiest)**

1. Look at the **bottom-right corner** of VS Code
2. You'll see a device selector (might say "No Device")
3. Click on it
4. Select **Chrome (web-javascript)** from the dropdown

**First time setup:**
```bash
flutter config --enable-web
```

### **Option B: Windows Desktop**

1. First, enable Windows desktop support:
```bash
flutter config --enable-windows-desktop
```

2. Click the device selector in bottom-right
3. Select **Windows (desktop-windows)**

### **Option C: Android Emulator**

1. First, start your Android emulator from Android Studio
2. Wait for it to boot up
3. Click the device selector in bottom-right
4. Select your emulator (e.g., "Pixel 5 API 33")

### **Option D: Physical Android Device**

1. Connect your Android phone via USB
2. Enable USB Debugging on your phone
3. Click the device selector in bottom-right
4. Select your device name

---

## ▶️ Step 5: Run the App

### **Method 1: Using the Play Button (Easiest)**

1. Open the file: `lib/main.dart`
2. Look at the top-right corner of VS Code
3. Click the **▶️ Play button** (or the Debug icon)
4. Wait for the app to compile and launch

### **Method 2: Using F5 Key**

1. Open `lib/main.dart`
2. Press **F5** on your keyboard
3. Select **Dart & Flutter** if prompted

### **Method 3: Using Command Palette**

1. Press **Ctrl+Shift+P**
2. Type: `Flutter: Launch Emulator`
3. Or type: `Flutter: Run Flutter Doctor`

### **Method 4: Using Terminal**

In the VS Code terminal, run:
```bash
flutter run
```

Or specify a device:
```bash
# For Chrome
flutter run -d chrome

# For Windows
flutter run -d windows

# For specific device
flutter run -d <device-id>
```

---

## ✅ Step 6: Verify It's Running

### You should see:

**In the Terminal:**
```
Launching lib\main.dart on Chrome in debug mode...
Building application for the web...
✓ Built build\web
```

**In Chrome/Windows:**
- App window opens
- Shows "Gezondheids Tracker" title
- Bottom navigation with 3 tabs: Dagboek, Toevoegen, Analyse
- Sample data displayed (13 days of entries)

### In VS Code Status Bar (bottom):
- Shows: "Running on Chrome" (or your device)
- Shows: "Flutter SDK 3.x.x"
- Shows: "Dart SDK 3.x.x"

---

## 🔥 Step 7: Use Hot Reload (Super Useful!)

Once your app is running, you can instantly see changes:

### **Hot Reload (Fast - Preserves State)**
1. Make a change to your code (e.g., change a text)
2. Save the file (`Ctrl+S`)
3. Press `r` in the terminal
   - Or click the ⚡ lightning icon in VS Code debug toolbar
   - Or press: `Ctrl+F5`

**Changes appear in ~1 second without restarting!**

### **Hot Restart (Full Restart)**
1. Press `R` (capital R) in the terminal
2. Or click the 🔄 circular arrow in VS Code debug toolbar
3. Or press: `Shift+F5` then `F5`

**Use this when:** Hot reload doesn't work (e.g., after adding new files)

---

## 🐛 Troubleshooting

### Problem: "Flutter SDK not found"

**Solution:**
1. Open Terminal in VS Code
2. Run: `flutter doctor`
3. If command not found:
   - Install Flutter SDK
   - Add to PATH
   - Restart VS Code

### Problem: "No devices found"

**Solution:**
1. For Chrome:
```bash
flutter config --enable-web
```

2. For Windows:
```bash
flutter config --enable-windows-desktop
```

3. Restart VS Code
4. Check device selector again

### Problem: "Unable to locate Android SDK"

**Solution:**
1. Install Android Studio
2. Open Android Studio
3. Go to: Tools > SDK Manager
4. Install latest Android SDK
5. Restart VS Code

### Problem: "Waiting for another flutter command to release the startup lock"

**Solution:**
1. Close VS Code
2. Delete: `C:\Users\<YourName>\AppData\Local\Pub\Cache\.flutter_tool_state`
3. Reopen VS Code

### Problem: Dependencies not found

**Solution:**
```bash
flutter clean
flutter pub get
```

### Problem: "pubspec.yaml" errors

**Solution:**
1. Check for syntax errors in `pubspec.yaml`
2. Ensure proper indentation (use spaces, not tabs)
3. Run: `flutter pub get`

---

## 🎨 VS Code Tips for Flutter Development

### **Useful Shortcuts:**

- `F5` - Start debugging
- `Ctrl+F5` - Start without debugging
- `Shift+F5` - Stop debugging
- `Ctrl+` ` - Toggle terminal
- `Ctrl+Shift+P` - Command Palette
- `Ctrl+Shift+F` - Search in all files
- `Ctrl+P` - Quick file open
- `Ctrl+Space` - Trigger autocomplete

### **Flutter Commands (Ctrl+Shift+P):**

- `Flutter: New Project` - Create new project
- `Flutter: Run Flutter Doctor` - Check setup
- `Flutter: Clean` - Clean build files
- `Flutter: Get Packages` - Download dependencies
- `Flutter: Upgrade Packages` - Update dependencies
- `Flutter: Launch Emulator` - Start Android emulator
- `Flutter: Change SDK` - Switch Flutter version

### **Debug Console:**

While debugging, you can:
- See print() statements
- View error messages
- Check variable values
- Use breakpoints (click left of line numbers)

### **Widget Inspector:**

1. While app is running, press `Ctrl+Shift+P`
2. Type: `Flutter: Open Widget Inspector`
3. See your UI tree structure
4. Debug layout issues

---

## 📱 Testing Your App

### **Basic Test Flow:**

1. **Start the app** (F5)
2. **Check Dagboek tab** - See 13 sample entries
3. **Click Toevoegen tab** - Try adding data
4. **Click Analyse tab** - Run AI analysis
5. **Make a code change** - Change a text
6. **Hot reload** (Ctrl+S) - See change instantly

### **Test the Analysis:**

1. Go to **Analyse** tab
2. Click **"Start AI Analyse"** button
3. Wait ~1.5 seconds
4. Should see:
   - Eczema overview
   - Pattern: "Frequent: Melk"
   - Correlation: "Melk verergert eczeem"
   - Charts with data

---

## 🎯 Quick Start Checklist

- [ ] Flutter SDK installed
- [ ] VS Code installed
- [ ] Flutter & Dart extensions installed in VS Code
- [ ] Project opened in VS Code
- [ ] Terminal opened (`` Ctrl+` ``)
- [ ] Run: `flutter pub get`
- [ ] Device selected (bottom-right corner)
- [ ] File `lib/main.dart` opened
- [ ] Press F5 to run
- [ ] App launches successfully
- [ ] Try hot reload (make a change, Ctrl+S)

---

## 🚀 You're Ready!

Once you see the app running with the 3 tabs (Dagboek, Toevoegen, Analyse), you're all set!

### **Next Steps:**
1. Test all 3 tabs
2. Add your own data
3. Run the AI analysis
4. Try hot reload with code changes
5. Explore the Flutter widgets

---

## 📚 Additional Resources

- **Flutter Docs:** https://docs.flutter.dev/
- **Dart Docs:** https://dart.dev/
- **VS Code Flutter:** https://dartcode.org/
- **Flutter Widget Catalog:** https://docs.flutter.dev/ui/widgets

---

**Happy Coding! 🎉**

*Your GezondheidsTracker app is ready to run from VS Code!*
