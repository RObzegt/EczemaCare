# Codemagic — EczemaCare / TriggerTrace

Stappen om builds op [Codemagic](https://codemagic.io) te laten draaien voor repo  
`https://github.com/RObzegt/EczemaCare`.

## 1. App koppelen

1. Log in op Codemagic → **Add application**.
2. Kies team → koppel **GitHub** → selecteer **EczemaCare**.
3. Kies branch **main** → **Check for configuration file** (moet `codemagic.yaml` vinden).
4. Zet **Project type** op Flutter.

## 2. Workflows in `codemagic.yaml`

| Workflow       | Doel                                      | Signing nodig? |
|----------------|-------------------------------------------|----------------|
| `ios-verify`   | `flutter analyze` + iOS compile check     | Nee            |
| `ios-release`  | IPA + upload naar TestFlight                | Ja             |

**Tip:** start eerst met **ios-verify**. Als die slaagt, draai **ios-release**.

## 3. Environment variable groups

Maak in Codemagic → app → **Environment variables** twee groups:

### Group `apiconfig`

| Variabele                 | Secret | Opmerking                          |
|---------------------------|--------|------------------------------------|
| `REVENUECAT_APPLE_KEY`    | Ja     | RevenueCat iOS public API key      |
| `REVENUECAT_GOOGLE_KEY`   | Ja     | RevenueCat Android key (placeholder ok voor alleen iOS) |

### Group `apple_auth`

Alleen nodig als je **geen** App Store Connect-integratie gebruikt. Bij `auth: integration` (standaard in yaml) volstaat stap 4.

| Variabele                         | Secret | Opmerking                    |
|-----------------------------------|--------|------------------------------|
| `APP_STORE_CONNECT_ISSUER_ID`     | Ja     | App Store Connect API        |
| `APP_STORE_CONNECT_KEY_IDENTIFIER`| Ja     | Key ID                       |
| `APP_STORE_CONNECT_PRIVATE_KEY`   | Ja     | Inhoud `.p8` (base64 of tekst)|

Koppel beide groups aan workflow **ios-release** (staat al in yaml).

## 4. App Store Connect-integratie

In Codemagic → **Team integrations** → **Developer Portal** / App Store Connect:

1. Naam: **`EczemaCare`** (moet exact overeenkomen met `integrations.app_store_connect` in `codemagic.yaml`).
2. Upload `.p8`, vul **Issuer ID** en **Key ID** in.

Zonder deze integratie faalt TestFlight-upload aan het einde van **ios-release**.

## 5. Code signing (iOS)

Codemagic → **Code signing identities** → tab **iOS**:

1. **Distribution certificate** (Apple Distribution) voor team `JTY452RWN4`.
2. **Provisioning profile** voor bundle `com.orions.eczemacare` (App Store).
   - Reference name in yaml: via `bundle_identifier` (geen vaste profielnaam meer vereist).
   - Lokaal profiel in repo: `EczemaCare_ios_app_store_1772991975.mobileprovision` (alleen ter referentie).

## 6. Build starten

- **Handmatig:** Codemagic → app → workflow **ios-verify** of **ios-release** → **Start new build**.
- **Automatisch:** push naar `main` of tag `v*` (zie `triggering` in yaml).

Versienummer: **ios-release** verhoogt het patch-nummer t.o.v. `pubspec.yaml` en zet build number op `CM_BUILD_NUMBER + 500`.

## 7. Veelvoorkomende fouten

| Fout | Oplossing |
|------|-----------|
| Geen `codemagic.yaml` gevonden | Bestand moet in repo-root op `main` staan |
| Unknown variable group | Groups `apiconfig` en `apple_auth` aanmaken en koppelen |
| Integration `EczemaCare` not found | Integratie in stap 4 aanmaken met exact die naam |
| Pod / Manifest.lock mismatch | Workflow draait al `flutter build ios --config-only` + `pod install` |
| Signing / profile | Certificaat + App Store-profiel uploaden voor `com.orions.eczemacare` |
| `flutter` niet gevonden | Project type Flutter + `flutter: stable` in yaml |

## 8. Na een lokale wijziging

```bash
git add codemagic.yaml CODEMAGIC.md
git commit -m "Configure Codemagic workflows and setup guide"
git push origin main
```

Daarna in Codemagic opnieuw **Check for configuration file** als workflows niet verschijnen.
