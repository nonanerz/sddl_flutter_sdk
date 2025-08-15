import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'models/link_data.dart';

class SddlApi {
  static const _base = 'https://sddl.me/api';

  /// GET /api/{key}/details
  static Future<LinkData?> getLinkData(String key) async {
    final uri = Uri.parse('$_base/$key/details');
    final resp = await http.get(uri, headers: await _commonHeaders());
    if (resp.statusCode == 200) {
      return LinkData.fromJson(jsonDecode(resp.body));
    }
    return null;
  }

  /// GET /api/try/details
  static Future<LinkData?> getTryDetails() async {
    final uri = Uri.parse('$_base/try/details');
    final resp = await http.get(uri, headers: await _commonHeaders());
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
      final id = info.packageName;
      if (id.isNotEmpty) {
        headers['X-App-Identifier'] = id;
      }
    } catch (_) {
    }
    return headers;
  }

  static String _platform() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Flutter';
  }
}
