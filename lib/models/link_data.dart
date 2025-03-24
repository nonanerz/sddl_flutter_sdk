class LinkData {
  final String? keyName;
  final String? fallbackUrl;
  final String? iosUrl;
  final String? androidUrl;
  final String? webUrl;
  final String? passthrough;
  final String? scheme;
  final String? webhookUrl;
  final Map<String, dynamic>? metaData;
  final Map<String, dynamic>? extraData;

  LinkData({
    this.keyName,
    this.fallbackUrl,
    this.iosUrl,
    this.androidUrl,
    this.webUrl,
    this.passthrough,
    this.scheme,
    this.webhookUrl,
    this.metaData,
    this.extraData,
  });

  factory LinkData.fromJson(Map<String, dynamic> json) {
    return LinkData(
      keyName: json['keyName'],
      fallbackUrl: json['fallbackUrl'],
      iosUrl: json['iosUrl'],
      androidUrl: json['androidUrl'],
      webUrl: json['webUrl'],
      passthrough: json['passthrough'],
      scheme: json['scheme'],
      webhookUrl: json['webhookUrl'],
      metaData: json['metaData'] ?? {},
      extraData: json['extraData'] ?? {},
    );
  }

  @override
  String toString() => 'LinkData(keyName: $keyName, iosUrl: $iosUrl, androidUrl: $androidUrl)';
}