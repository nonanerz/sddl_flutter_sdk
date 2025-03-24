import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/link_data.dart';

class SddlApi {
  static const _baseUrl = 'https://sddl.me/api';
  static Future<LinkData?> getLinkData(String key) async {
    final response = await http.get(Uri.parse('$_baseUrl/$key/details'));

    if (response.statusCode == 200) {
      return LinkData.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}