import 'package:uni_links/uni_links.dart';
import '../api.dart';
import '../models/link_data.dart';

class DeepLinkHandler {
  static void listen(Function(LinkData?) onLinkReceived) {
    uriLinkStream.listen((Uri? uri) async {
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final key = uri.pathSegments.last;
        final data = await SddlApi.getLinkData(key);
        onLinkReceived(data);
      }
    });
  }
}