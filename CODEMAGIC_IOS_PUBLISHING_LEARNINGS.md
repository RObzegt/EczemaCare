# iOS Codemagic Publishing - Lessons Learned
_Documented so future builds to TestFlight go smoothly._

## 1. Environment Variables in `codemagic.yaml`
When referencing environment variables in the `codemagic.yaml` script, especially in the `publishing` block, you must ensure the group is imported.
- Define a group in Codemagic UI > Environment Variables (e.g., `apple_auth`).
- **CRUCIAL:** Add that group to the `codemagic.yaml` file under `environment` -> `groups`!
- Do not use `$` when assigning the `app_store_connect` keys if omitting the dollar sign is how Codemagic expects to resolve the secret. *Wait, actually we ended up importing the group and keeping the `$` prefix based on standard bash/yaml interpolation, though some Codemagic blocks prefer it without. What worked was `api_key: $APP_STORE_CONNECT_PRIVATE_KEY` combined with importing the group.*

## 2. The `.p8` Apple Private Key Format
When pasting the App Store Connect Private Key into the Codemagic Environment Variables (e.g., `APP_STORE_CONNECT_PRIVATE_KEY`):
- **ALWAYS** include the header and footer: `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.
- Paste the raw text exactly as it appears in the `.p8` file. If any newlines or dashes are missing, Apple will reject the API call with "Provided value is not a valid PEM encoded private key".

## 3. The TestFlight Publishing Block Parameter Name
Codemagic documentation can be strict. For Apple integrations in the `publishing` block:
- Use `issuer_id`
- Use `key_id`
- Use **`api_key`** (NOT `auth_key` or `private_key`!) to pass the actual PEM string variable.

## 4. `flutter build ipa` vs `xcode-project build-ipa`
When using **Manual** Code Signing (`CODE_SIGN_STYLE = Manual` in `project.pbxproj`), the standard command `flutter build ipa` often strips the manually injected provisioning profiles during the final `.xcarchive` export phase, resulting in the error: *requires a provisioning profile*.

**THE FIX:** Separate the build and package steps:
1. `flutter build ios --release --no-codesign` (Compiles the raw iOS framework)
2. `xcode-project build-ipa --workspace ios/Runner.xcworkspace --scheme Runner` (Codemagic's native tool safely hard-links the manual provisioning profiles during the IPA export).

## 5. Finding the Output Artifact
After `xcode-project build-ipa` finishes, it places the `.ipa` file precisely at:
`build/ios/ipa/*.ipa`

In the `artifacts:` section of `codemagic.yaml`, make sure to explicitly use this path relative to the working directory so Codemagic can find it to upload.

## 6. The "MinimumOSVersion" Plist Bug in Flutter
Apple's App Store Connect now strictly validates that all embedded third-party frameworks declare a minimum supported iOS version. The default Flutter template for `AppFrameworkInfo.plist` (located in `ios/Flutter/`) is missing this field.
If omitted, Apple rejects the bundle with: *Invalid Bundle. The bundle Runner.app/Frameworks/App.framework does not support the minimum OS Version specified in the Info.plist.*

**THE FIX:** Always ensure `ios/Flutter/AppFrameworkInfo.plist` contains the following snippet matching your Xcode project's deployment target:
```xml
  <key>MinimumOSVersion</key>
  <string>13.0</string>
```

---

**Summary Routine for updating the App:**
1. Bump the `version:` in `pubspec.yaml` (e.g., `1.3.1+4`).
2. Push to GitHub `main` branch.
3. Open Codemagic, hit *Start new build* on the `ios-release` workflow.
4. Because all the above fixes are now hardcoded in the repo, the app will compile, package the certificates, correctly find the IPA, authenticate flawlessly via the environment variables, and appear automatically in your Apple TestFlight dashboard moments later!
