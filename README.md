# SDDL Flutter SDK

Flutter SDK for sddl.me — simple deep links and mobile attribution.

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  sddl_sdk: ^0.1.0
```

Then run:

```bash
flutter pub get
```

---

## Platform setup

### Android

Add an intent filter in `AndroidManifest.xml` (use your domain):

```xml
<activity ...>
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="{YOUR_SUBDOMAIN}.sddl.me" />
    <!-- or your custom domain -->
    <!-- <data android:scheme="https" android:host="go.example.com" /> -->
  </intent-filter>
</activity>
```

### iOS

Enable **Associated Domains** for Universal Links in Xcode (Target → Signing & Capabilities → + Capability → Associated Domains), e.g.:

```
applinks:{YOUR_ID}.sddl.me
```

or your custom domain.

---

## Usage

Initialize the SDK once and provide handlers for success and error. Recommended place — root widget’s `initState`, and call `dispose()` when the widget is destroyed.

```dart
import 'package:flutter/material.dart';
import 'package:sddl_sdk/sddl_sdk.dart';
import 'package:sddl_sdk/models/link_data.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Sddl.init(
      onSuccess: _onDeepLink,
      onError: (err) => debugPrint('SDDL error: $err'),
    );
  }

  @override
  void dispose() {
    Sddl.dispose();
    super.dispose();
  }

  void _onDeepLink(LinkData data) {
    // Example routing using payload
    // navigatorKey.currentState?.pushNamed('/product', arguments: data.metaData);
    debugPrint('SDDL payload: ${data.toJson()}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(
        body: Center(child: Text('Ready for deep links')),
      ),
    );
  }
}
```

---

## Resolution order (SDK behavior)

- If a Universal/App Link URL is delivered: the SDK uses only that URL.
    - If the first path segment is a valid key → `GET /api/{key}/details` (query params are preserved).
    - If the URL has no valid key → `GET /api/try/details`.
- If no URL (cold start): short internal delay to allow a late UL; then
    - If clipboard contains a valid key → `GET /api/{key}/details`.
    - Otherwise → `GET /api/try/details`.

> Key is expected in the **first** path segment, e.g. `https://sddl.me/AbCd1234?...` → `AbCd1234`.

---

## LinkData example

```json
{
  "keyName": "AbCd1234",
  "fallbackUrl": "https://...",
  "iosUrl": "https://...",
  "androidUrl": "https://...",
  "metaData": { "slug": "pizza-margherita" },
  "extraData": {
    "ip": "...",
    "userAgent": "...",
    "createdAt": "..."
  }
}
```

---

## Troubleshooting

- Android: the intent-filter host must match your deep link domain.
- iOS: verify Associated Domains and that your AASA file is accessible.
- Call `Sddl.init` only once; pair it with `Sddl.dispose` when appropriate.


Powered by [sddl.me](https://sddl.me)
