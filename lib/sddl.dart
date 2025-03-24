import '/api.dart';
import '/utils/deep_link_handler.dart';
import '/models/link_data.dart';

import 'package:uni_links/uni_links.dart';

class Sddl {
  static void init({required Function(LinkData?) onLinkReceived}) {
    uriLinkStream.listen((uri) async {
      final linkData = await _resolveUri(uri);
      onLinkReceived(linkData);
    });

    _handleInitialUri(onLinkReceived);
  }

  static Future<void> _handleInitialUri(Function(LinkData?) onLinkReceived) async {
    final uri = await getInitialUri();
    final linkData = await _resolveUri(uri);
    onLinkReceived(linkData);
  }

  static Future<LinkData?> _resolveUri(Uri? uri) async {
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final key = uri.pathSegments.last;
    return await SddlApi.getLinkData(key);
  }
}