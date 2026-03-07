# Eczema Care - Deployment Guide

This guide explains how to take the files in `C:\Down\orions2\eczema_care` and successfully deploy them to GitHub, Render (Backend), and the iOS App Store.

## 1. GitHub Setup
To manage your code and enable Render deployment, push this directory to a new Private GitHub repository.

1. Create a new repository on GitHub named `eczema_care`.
2. In your terminal (inside `C:\Down\orions2\eczema_care`):
   ```bash
   git init
   git add .
   git commit -m "Initial commit for Eczema Care"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/eczema_care.git
   git push -u origin main
   ```

## 2. Render Deployment (Backend/Web)
Since you have a `Dockerfile` and `routes` (Dart Frog), you can host your backend or web version on Render.

1. Go to [Render.com](https://render.com) and create a new **Web Service**.
2. Connect your GitHub repository `eczema_care`.
3. Render will detect the `Dockerfile`.
4. Set the **Environment** to `Docker`.
5. Click **Deploy**. Your backend will be live at `https://eczema-care.onrender.com`.

## 3. iOS App Store Submission
To put the app on the App Store, you need a Mac with Xcode.

### A. Prerequisites
- **Apple Developer Account** (Required for App Store).
- **Xcode** installed on a Mac.

### B. Configuration
1. Open `ios/Runner.xcworkspace` in Xcode.
2. In **General** settings:
   - **Bundle Identifier**: Change `com.example.gezondheidsTracker` to something unique like `com.orions.eczemacare`.
   - **Display Name**: Ensure it is set to `Eczema Care`.
3. In **Signing & Capabilities**:
   - Select your **Team** (Developer Account).

### C. Build & Upload
1. In the terminal:
   ```bash
   flutter build ios --release
   ```
2. In Xcode, select **Product > Archive**.
3. Once the archive is finished, click **Distribute App** and follow the prompts to upload to App Store Connect.

## 4. Final Review Checklist
- [ ] **Icons**: Add app icons to `ios/Runner/Assets.xcassets`.
- [ ] **Privacy**: Ensure you have a Privacy Policy URL (Render can host this!).
- [ ] **AI Disclosure**: When submitting, mention that the app uses statistical algorithms for pattern detection.
