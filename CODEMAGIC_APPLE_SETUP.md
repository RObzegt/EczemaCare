# Apple Developer Integration with Codemagic

To enable automatic code signing and publishing for your iOS app, you need to link your Apple Developer account to Codemagic using an **App Store Connect API Key**.

## 1. Generate API Key in App Store Connect
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Go to **Users and Access** > **Integrations** (or **Keys**).
3. Click the **+** icon to generate a new API Key.
4. Name it `Codemagic API Key` and set the access level to **App Manager** or **Admin**.
5. Once generated, note down:
    - **Issuer ID** (at the top of the page).
    - **Key ID**.
    - **Private Key file** (.p8) - download this immediately as you can only do it once.

## 2. Configure Codemagic Environment
1. In your Codemagic project settings, go to the **Environment variables** tab.
2. Create a new group called **`apple_auth`**.
3. Add the following variables to this group:
    - `APP_STORE_CONNECT_ISSUER_ID`: (Your Issuer ID)
    - `APP_STORE_CONNECT_KEY_IDENTIFIER`: (Your Key ID)
    - `APP_STORE_CONNECT_PRIVATE_KEY`: (Open the .p8 file in a text editor and copy the *entire* content)

## 3. Update `codemagic.yaml`
Your current `codemagic.yaml` is already set up to use these credentials through the `apple_auth` group.

```yaml
environment:
  groups:
    - apple_auth
  vars:
    APP_ID: your_app_id_here # Found in App Store Connect -> App Information
    BUNDLE_ID: "com.orions.eczemacare"
```

## 4. Automatic Code Signing
The command `app-store-connect fetch-signing-files` (already in your script) will now:
- Automatically download your distribution certificates.
- Generate or download the required provisioning profiles.
- Prepare the build for the App Store.

> [!TIP]
> After setting up the variables, try running a build in Codemagic. It should now successfully sign the IPA and prepare it for upload.
