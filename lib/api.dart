import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/link_data.dart';

class SddlApi {
  static const _base = 'https://sddl.me/api';

  /// GET /api/{key}/details[?query]
  static Future<LinkData?> getLinkData(String key, {String? query}) async {
    final uri =
        Uri.parse('$_base/$key/details${query != null ? '?$query' : ''}');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return LinkData.fromJson(jsonDecode(resp.body));
    }
    return null;
  }
}
