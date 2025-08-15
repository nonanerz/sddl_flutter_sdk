import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

import 'models/link_data.dart';
import 'api.dart';

class Sddl {
  static StreamSubscription? _sub;
  static Timer? _coldTimer;

  static bool _resolving = false; // single-flight
  static bool _ulArrived = false; // UL has arrived during this session

  /// Start listening. Call once (e.g., in initState).
  static void init({
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
  }) {
    // 1) Stream for runtime links
    _sub?.cancel();
    _sub = uriLinkStream.listen((Uri? uri) async {
      _ulArrived = true;
      await _resolveFromUri(
        uri: uri,
        onSuccess: onSuccess,
        onError: onError,
      );
    }, onError: (e) {
      onError?.call('uni_links stream error: $e');
    });

    // 2) Cold start (no URL yet)
    _handleColdStart(onSuccess: onSuccess, onError: onError);
  }

  /// Stop listening. Call in dispose().
  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _coldTimer?.cancel();
    _coldTimer = null;
    _resolving = false;
    _ulArrived = false;
  }

  // ---- Internals -----------------------------------------------------------

  static Future<void> _handleColdStart({
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
  }) async {
    try {
      final initial = await getInitialUri(); // may be null
      if (initial != null) {
        _ulArrived = true;
        await _resolveFromUri(
          uri: initial,
          onSuccess: onSuccess,
          onError: onError,
        );
        return;
      }
    } catch (e) {
      onError?.call('getInitialUri error: $e');
    }

    // Small delay so a late UL can arrive first
    _coldTimer?.cancel();
    _coldTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_ulArrived) return; // UL won
      if (_resolving) return; // single-flight

      // Clipboard → /api/{key}/details → else /api/try/details
      final clipKey = await _readClipboardKey();
      if (clipKey != null) {
        await _getDetails(
          key: clipKey,
          onSuccess: onSuccess,
          onError: onError,
        );
      } else {
        await _getTryDetails(onSuccess: onSuccess, onError: onError);
      }
    });
  }

  static Future<void> _resolveFromUri({
    required Uri? uri,
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
  }) async {
    if (uri == null) return;
    if (_resolving) return;
    _resolving = true;

    try {
      final key = _extractKey(uri);
      if (key != null) {
        await _getDetails(
          key: key,
          onSuccess: onSuccess,
          onError: onError,
        );
      } else {
        await _getTryDetails(onSuccess: onSuccess, onError: onError);
      }
    } finally {
      _resolving = false;
    }
  }

  static String? _extractKey(Uri uri) {
    if (uri.pathSegments.isEmpty) return null;
    // first path segment only (aligned with Android/iOS)
    final first = uri.pathSegments.first.trim();
    final isValid = RegExp(r'^[A-Za-z0-9_-]{4,64}$').hasMatch(first);
    return isValid ? first : null;
  }

  static Future<String?> _readClipboardKey() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = (data?.text ?? '').trim();
      if (text.isEmpty) return null;
      final isValid = RegExp(r'^[A-Za-z0-9_-]{4,64}$').hasMatch(text);
      return isValid ? text : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _getDetails({
    required String key,
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
  }) async {
    try {
      final data = await SddlApi.getLinkData(key);
      if (data != null) {
        onSuccess(data);
      } else {
        // 404/410 or other → best effort
        await _getTryDetails(onSuccess: onSuccess, onError: onError);
      }
    } catch (e) {
      onError?.call('details error: $e');
    }
  }

  static Future<void> _getTryDetails({
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
  }) async {
    try {
      final data = await SddlApi.getTryDetails();
      if (data != null) {
        onSuccess(data);
      } else {
        onError?.call('try/details HTTP error');
      }
    } catch (e) {
      onError?.call('try/details error: $e');
    }
  }
}
