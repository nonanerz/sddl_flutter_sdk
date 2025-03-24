import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/link_data.dart';
import 'api.dart';

class Sddl {
  static void init({required Function(LinkData?) onLinkReceived}) {
    // Listen for incoming links when app is running
    uriLinkStream.listen((uri) async {
      final linkData = await _resolveUri(uri);
      onLinkReceived(linkData);
    });

    // Handle cold start
    _handleInitialUri(onLinkReceived);
  }

  static Future<void> _handleInitialUri(Function(LinkData?) onLinkReceived) async {
    try {
      final uri = await getInitialUri();
      final linkData = await _resolveUri(uri);

      if (linkData != null) {
        onLinkReceived(linkData);
      } else {
        // Try to resolve link via fallback API
        final fallbackData = await _fetchTryDetails();
        onLinkReceived(fallbackData);
      }
    } catch (e) {    }
  }

  static Future<LinkData?> _resolveUri(Uri? uri) async {
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final key = uri.pathSegments.last;
    return await SddlApi.getLinkData(key);
  }

  static Future<LinkData?> _fetchTryDetails() async {
    try {
      final response = await http.get(Uri.parse('https://sddl.me/api/try/details'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return LinkData.fromJson(jsonData);
      }
    } catch (e) {
    }
    return null;
  }
}