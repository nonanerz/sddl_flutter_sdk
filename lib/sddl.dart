import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';

import 'models/link_data.dart';
import 'api.dart';

class Sddl {
  static const _coldDelay = Duration(milliseconds: 300);
  static const _coldDoneKey = 'sddl.coldstartDone.v1';

  static StreamSubscription? _sub;
  static Timer? _coldTimer;
  static AppLinks? _appLinks;

  static bool _resolving = false;
  static bool _ulArrived = false;

  static void init({
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
    bool readClipboard = true,
  }) async {
    _appLinks = AppLinks();
    _sub?.cancel();
    _sub = _appLinks!.uriLinkStream.listen((Uri? uri) async {
      _ulArrived = true;
      _coldTimer?.cancel();
      await _resolveFromUri(
        uri: uri,
        onSuccess: onSuccess,
        onError: onError,
      );
    }, onError: (e) {
      onError?.call('app_links stream error: $e');
    });

    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) {
        _ulArrived = true;
        _coldTimer?.cancel();
        await _resolveFromUri(uri: initial, onSuccess: onSuccess, onError: onError);
        return;
      }
    } catch (e) {
      onError?.call('getInitialLink error: $e');
    }

    _handleColdStart(onSuccess: onSuccess, onError: onError, readClipboard: readClipboard);
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _coldTimer?.cancel();
    _coldTimer = null;
    _appLinks = null;
    _resolving = false;
    _ulArrived = false;
  }

  static Future<void> _handleColdStart({
    required void Function(LinkData data) onSuccess,
    void Function(String error)? onError,
    required bool readClipboard,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_coldDoneKey) == true) return;

    _coldTimer?.cancel();
    _coldTimer = Timer(_coldDelay, () async {
      if (_ulArrived) return;
      if (_resolving) return;
      _resolving = true;
      try {
        await prefs.setBool(_coldDoneKey, true);

        final clipKey = readClipboard ? await _readClipboardKey() : null;
        if (clipKey != null) {
          final data = await SddlApi.getLinkData(clipKey);
          if (data != null) {
            onSuccess(data);
            return;
          }
        }
        final data = await SddlApi.getTryDetails();
        if (data != null) {
          onSuccess(data);
        } else {
          onError?.call('try/details HTTP error');
        }
      } catch (e) {
        onError?.call('cold start error: $e');
      } finally {
        _resolving = false;
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
      final key = _extractIdentifier(uri);
      if (key != null) {
        final data = await SddlApi.getLinkData(key, query: uri.query);
        if (data != null) {
          onSuccess(data);
        } else {
          final tryData = await SddlApi.getTryDetails();
          if (tryData != null) {
            onSuccess(tryData);
          } else {
            onError?.call('details fallback error');
          }
        }
      } else {
        final tryData = await SddlApi.getTryDetails();
        if (tryData != null) {
          onSuccess(tryData);
        } else {
          onError?.call('try/details HTTP error');
        }
      }
    } catch (e) {
      onError?.call('resolve error: $e');
    } finally {
      _resolving = false;
    }
  }

  static String? _extractIdentifier(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      final first = uri.pathSegments.first.trim();
      if (RegExp(r'^[A-Za-z0-9_-]{4,64}$').hasMatch(first)) return first;
    }
    final host = (uri.host).trim();
    if (RegExp(r'^[A-Za-z0-9_-]{4,64}$').hasMatch(host)) return host;
    return null;
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
}