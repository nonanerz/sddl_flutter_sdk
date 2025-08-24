import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'models/link_data.dart';

class SddlApi {
  static const _base = 'https://sddl.me/api';
  static const _timeout = Duration(seconds: 5);

  static Future<LinkData?> getLinkData(String key, {String? query}) async {
    final uri = Uri.parse('$_base/$key/details')
        .replace(query: (query != null && query.isNotEmpty) ? query : null);
    final resp = await http.get(uri, headers: await _commonHeaders()).timeout(_timeout);
    if (resp.statusCode == 200) {
      return LinkData.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  static Future<LinkData?> getTryDetails() async {
    final uri = Uri.parse('$_base/try/details');
    final resp = await http.get(uri, headers: await _commonHeaders()).timeout(_timeout);
    if (resp.statusCode == 200) {
      return LinkData.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  static Future<Map<String, String>> _commonHeaders() async {
    final headers = <String, String>{
      'User-Agent': 'SDDLSDK-Flutter/1.0',
      'X-Device-Platform': _platform(),
    };

    try {
      final info = await PackageInfo.fromPlatform();
      if (info.packageName.isNotEmpty) {
        headers['X-App-Identifier'] = info.packageName;
      }
    } catch (_) {}

    try {
      final loc = Platform.localeName.replaceAll('_', '-');
      headers['X-Client-Language'] = loc;
    } catch (_) {}

    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      if (tz.isNotEmpty) headers['X-Client-Timezone'] = tz;
    } catch (_) {}

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        headers['X-Client-OS-Version'] = ios.systemVersion.split('.').first;
      } else if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final rel = (android.version.release ?? '').trim();
        final relDigits = RegExp(r'^\d+').firstMatch(rel)?.group(0);
        headers['X-Client-OS-Version'] = relDigits?.isNotEmpty == true
            ? relDigits!
            : '${android.version.sdkInt}';
      } else {
        final m = RegExp(r'\d+').firstMatch(Platform.operatingSystemVersion);
        headers['X-Client-OS-Version'] = m?.group(0) ?? Platform.operatingSystemVersion;
      }
    } catch (_) {}

    try {
      final pixelRatio = ui.window.devicePixelRatio;
      final size = ui.window.physicalSize;
      final cssW = (size.width / pixelRatio).round();
      final cssH = (size.height / pixelRatio).round();
      headers['X-Client-Screen-Width'] = '$cssW';
      headers['X-Client-Screen-Height'] = '$cssH';
    } catch (_) {}

    return headers;
  }

  static String _platform() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Flutter';
  }
}