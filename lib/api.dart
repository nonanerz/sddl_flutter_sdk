import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sddl_sdk/referrer.dart';

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
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        headers['X-Client-OS-Version'] = ios.systemVersion;
      } else if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        headers['X-Client-OS-Version'] =
        (android.version.release ?? '').trim().isNotEmpty
            ? (android.version.release ?? '').trim()
            : '${android.version.sdkInt}';
      } else {
        headers['X-Client-OS-Version'] = Platform.operatingSystemVersion;
      }
    } catch (_) {}


    try {
      final tz = await FlutterTimezone.getLocalTimezone()
          .timeout(const Duration(milliseconds: 500));
      if (tz.isNotEmpty) headers['X-Client-Timezone'] = tz;
    } catch (_) {}

    try {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      final views = dispatcher.views;
      if (views.isNotEmpty) {
        final v = views.first;
        final pixelRatio = v.devicePixelRatio;
        final size = v.physicalSize;
        final cssW = (size.width / pixelRatio).round();
        final cssH = (size.height / pixelRatio).round();
        headers['X-Client-Screen-Width'] = '$cssW';
        headers['X-Client-Screen-Height'] = '$cssH';
      }
    } catch (_) {}

    try {
      final info = await SddlReferrer.get(waitMs: 350);
      if (info.hasData) {
        headers['X-Install-Referrer'] = info.raw;
        if (info.clickTsSec > 0) headers['X-Referrer-Click-Ts'] = '${info.clickTsSec}';
        if (info.installBeginTsSec > 0) headers['X-Install-Begin-Ts'] = '${info.installBeginTsSec}';
        final p = info.params;
        if (p['utm_source'] != null) headers['X-UTM-Source'] = p['utm_source']!;
        if (p['utm_medium'] != null) headers['X-UTM-Medium'] = p['utm_medium']!;
        if (p['utm_campaign'] != null) headers['X-UTM-Campaign'] = p['utm_campaign']!;
        if (p['utm_term'] != null) headers['X-UTM-Term'] = p['utm_term']!;
        if (p['utm_content'] != null) headers['X-UTM-Content'] = p['utm_content']!;
        if (p['gclid'] != null) headers['X-GCLID'] = p['gclid']!;
        final sddl = p['sddl'] ?? p['sddl_id'];
        if (sddl != null) headers['X-SDDL-ID'] = sddl;
      }
    } catch (_) {}

    return headers;
  }

  static String _platform() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Flutter';
  }
}