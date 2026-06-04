# Codemagic — EczemaCare / TriggerTrace

Repo: `https://github.com/RObzegt/EczemaCare`  
Bundle ID: `com.orions.eczemacare` | Team: `JTY452RWN4`

---

## Workflows

| Workflow | Wat het doet | Trigger | IPA? |
|----------|-------------|---------|------|
| **ios-verify** | Compile-check zonder signing | Handmatig | Nee |
| **ios-release** | Bouwt IPA → TestFlight | Tag `v*` of handmatig | **Ja** |

---

## Stap-voor-stap setup in Codemagic

### 1. App koppelen
1. [codemagic.io](https://codemagic.io) → **Add application**
2. Koppel GitHub → selecteer repo **EczemaCare**
3. Branch **main** → **Check for configuration file** → kiest `codemagic.yaml`

### 2. Environment variable groups

Ga naar app → **Environment variables** → maak twee groups.

**Group `apiconfig`**

| Variabele | Waarde | Secret |
|-----------|--------|--------|
| `REVENUECAT_APPLE_KEY` | RevenueCat iOS API key | ✓ |
| `REVENUECAT_GOOGLE_KEY` | RevenueCat Android key | ✓ |

**Group `apple_auth`** ← vereist voor TestFlight-upload

| Variabele | Waarde | Secret |
|-----------|--------|--------|
| `APP_STORE_CONNECT_ISSUER_ID` | UUID uit App Store Connect | ✓ |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Key ID (10 tekens) | ✓ |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Inhoud `.p8` bestand | ✓ |

App Store Connect API key aanmaken: **Users & Access → Integrations → App Store Connect API → + nieuw** (rol: App Manager of hoger). Download `.p8` — slechts één keer downloadbaar.

Koppel beide groups aan workflow **ios-release** via de workflow-instellingen in Codemagic.

### 3. Code signing identities

Ga naar app → **Code signing identities** → tab **iOS**:

1. **Certificate**: upload Apple Distribution `.p12` voor team `JTY452RWN4`
2. **Provisioning profile**: upload App Store profiel voor `com.orions.eczemacare`
   - Reference name moet exact zijn: **`EczemaCare ios_app_store 1772991975`**
   - Of: download nieuw profiel via Apple Developer → Profiles

### 4. Build starten

**ios-verify** (eerst testen):
- Codemagic → app → **Start new build** → workflow **ios-verify**

**ios-release** (IPA + TestFlight):
- Optie A: tag pushen → `git tag v5.0.9 && git push origin v5.0.9`
- Optie B: **Start new build** → workflow **ios-release**

---

## Wat er in het project is geregeld

- `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` staat in alle Runner-configs (Debug/Release/Profile) → IAP-entitlement meegezet in binary
- `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` in alle project-configs → geen archive-crash op Xcode 16+
- Versienummer = pubspec.yaml versie | build number = `CM_BUILD_NUMBER + 500`

---

## Veelvoorkomende fouten

| Fout | Oplossing |
|------|-----------|
| ios-verify OK maar geen TestFlight | Start **ios-release**, niet ios-verify |
| `Unknown variable group 'apiconfig'` | Group aanmaken en koppelen aan workflow |
| `No provisioning profile found` | Profiel uploaden met name `EczemaCare ios_app_store 1772991975` |
| `xcodebuild archive` exit 65 | Check archive.log in artifacts; meist signing- of entitlement-fout |
| `No such module 'purchases_flutter'` | `pod install --repo-update` opnieuw; pods-cache leegmaken |
| Build number rejected (duplicate) | App Store Connect accepteert alleen oplopende build nrs; verhoog `+ 500` offset |
