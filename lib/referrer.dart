import 'dart:async';
import 'package:flutter/services.dart';

class SddlReferrerInfo {
  final String raw;
  final int clickTsSec;
  final int installBeginTsSec;
  final Map<String, String> params;

  const SddlReferrerInfo({
    required this.raw,
    required this.clickTsSec,
    required this.installBeginTsSec,
    required this.params,
  });

  bool get hasData => raw.isNotEmpty;

  factory SddlReferrerInfo.fromMap(Map<dynamic, dynamic> map) {
    return SddlReferrerInfo(
      raw: (map['raw'] as String?) ?? '',
      clickTsSec: (map['clickTsSec'] as int?) ?? 0,
      installBeginTsSec: (map['installBeginTsSec'] as int?) ?? 0,
      params: Map<String, String>.from((map['params'] as Map?) ?? const {}),
    );
  }
}

class SddlReferrer {
  static const MethodChannel _ch = MethodChannel('sddl_referrer');

  static Future<SddlReferrerInfo> get({int waitMs = 350}) async {
    final res = await _ch.invokeMethod<Map<dynamic, dynamic>>(
      'getInstallReferrer',
      {'waitMs': waitMs},
    );
    return SddlReferrerInfo.fromMap(res ?? const {});
  }
}