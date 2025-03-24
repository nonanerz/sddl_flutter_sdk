
# 📱 SDDL SDK for Flutter

Flutter SDK for [sddl.me](https://sddl.me) — simple deep links and mobile attribution.  
Support for deep links with metadata, cold start handling, and easy integration.

## 🚀 Features

- ✅ Deep link handling (foreground and cold start)
- ✅ Extract link metadata (`user_id`, UTM params, etc.)
- ✅ Easily navigate to screens on link open

## 📦 Installation

In your `pubspec.yaml`:

```yaml
dependencies:
  sddl_sdk: ^0.0.7
```

Then run:

```bash
flutter pub get
```

## 🛠️ Setup

### Android

Update `AndroidManifest.xml` with an intent filter:

```xml
<activity ...>
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="{YOUR_SUBDOMAIN}.sddl.me" />
  </intent-filter>
</activity>
```

### iOS

Make sure to enable Universal Links in your `Info.plist`.

## 📲 Usage

Initialize SDDL in your `main.dart`, **after `runApp()`**:

```dart
void main() {
  runApp(MyApp());

  Sddl.init(onLinkReceived: (LinkData? data) {
    if (data != null) {
      print("🔗 Received deep link with slug: ${data.metaData?['user_id']}");
      // Navigate to screen using navigatorKey, etc.
    }
  });
}
```

> ℹ️ Make sure to set a global `navigatorKey` if you want to push screens.

## 📘 LinkData structure

```json
{
  "keyName": "AbCd1234",
  "fallbackUrl": "https://...",
  "iosUrl": "...",
  "androidUrl": "...",
  "metaData": {
    "slug": "pizza-margherita"
  },
  "extraData": {
    "ip": "...",
    "userAgent": "...",
    "createdAt": "...",
    ...
  }
}
```
