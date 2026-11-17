import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_config.dart';

List<int>? parseVersion(String value) {
  if (!RegExp(r'^[0-9]+(?:\.[0-9]+){0,2}$').hasMatch(value)) return null;
  final parts = value.split('.').map(int.parse).toList();
  return [...parts, ...List.filled(3 - parts.length, 0)];
}

int compareVersions(List<int> first, List<int> second) {
  for (var index = 0; index < 3; index++) {
    final result = first[index].compareTo(second[index]);
    if (result != 0) return result;
  }
  return 0;
}

class InstalledApp {
  const InstalledApp({
    required this.platform,
    required this.version,
    required this.buildNumber,
    required this.packageName,
    this.countryCode,
    this.osVersion,
  });

  final String platform;
  final String version;
  final int buildNumber;
  final String packageName;
  final String? countryCode;
  final String? osVersion;

  static Future<InstalledApp?> read() async {
    if (kIsWeb ||
        AppConfig.mockApi ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      return null;
    }
    final info = await PackageInfo.fromPlatform();
    final build = int.tryParse(info.buildNumber);
    if (build == null || build < 1 || parseVersion(info.version) == null) {
      return null;
    }
    final os = Platform.isIOS
        ? (await DeviceInfoPlugin().iosInfo).systemVersion
        : null;
    return InstalledApp(
      platform: Platform.isAndroid ? 'android' : 'ios',
      version: info.version,
      buildNumber: build,
      packageName: info.packageName,
      countryCode:
          WidgetsBinding.instance.platformDispatcher.locale.countryCode,
      osVersion: os,
    );
  }
}

class AppUpdate {
  const AppUpdate(
      {required this.platform,
      required this.minimumVersion,
      required this.minimumBuild,
      required this.storeUrl,
      this.title,
      this.message,
      this.isRequired = true});

  final String platform;
  final String? minimumVersion;
  final int? minimumBuild;
  final Uri storeUrl;
  final String? title;
  final String? message;
  final bool isRequired;

  String get identity => '$platform:$minimumVersion:$minimumBuild';

  static AppUpdate? fromJson(Map<String, dynamic> json, InstalledApp app) {
    if (json['update_required'] is! bool || json['platform'] != app.platform) {
      return null;
    }
    final required = json['update_required'] == true;
    if (!required && json['update_available'] != true) return null;
    final version = json[required ? 'minimum_version' : 'latest_version'];
    if (version != null && version is! String) return null;
    final minimum = version is String ? parseVersion(version) : null;
    final current = parseVersion(app.version);
    final build =
        json[required ? 'minimum_build_number' : 'latest_build_number'];
    final url = Uri.tryParse('${json['store_url'] ?? ''}');
    if (current == null ||
        (version != null && minimum == null) ||
        (build != null && (build is! int || build < 1)) ||
        url == null ||
        url.scheme != 'https' ||
        url.userInfo.isNotEmpty ||
        url.hasPort) {
      return null;
    }
    if (app.platform == 'android') {
      if (build is! int ||
          app.buildNumber >= build ||
          url.host != 'play.google.com' ||
          url.path != '/store/apps/details' ||
          !listEquals(url.queryParametersAll['id'], [app.packageName])) {
        return null;
      }
    } else if (app.platform == 'ios') {
      if (minimum == null ||
          compareVersions(current, minimum) >= 0 ||
          url.host != 'apps.apple.com' ||
          !RegExp(r'^/(?:[a-zA-Z]{2}/)?app/(?:[^/]+/)?id[0-9]+/?$')
              .hasMatch(url.path)) {
        return null;
      }
    } else {
      return null;
    }
    return AppUpdate(
        platform: app.platform,
        minimumVersion: version,
        minimumBuild: build,
        storeUrl: url,
        title: _noticeText(json['title']),
        message: _noticeText(json['message']),
        isRequired: required);
  }

  static String? _noticeText(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

typedef InstalledAppReader = Future<InstalledApp?> Function();
typedef StoreUpdateChecker = Future<bool> Function(
    InstalledApp app, AppUpdate update);

/// Public metadata only. Never uses the authenticated API client or clears a session.
class AppUpdateService {
  AppUpdateService(
      {required Dio dio,
      InstalledAppReader? readInstalled,
      StoreUpdateChecker? checkStore})
      : _dio = dio,
        _readInstalled = readInstalled ?? InstalledApp.read,
        _checkStore = checkStore;

  final Dio _dio;
  final InstalledAppReader _readInstalled;
  final StoreUpdateChecker? _checkStore;

  Future<AppUpdate?> check() async {
    try {
      return await _check().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Missing policy, offline, unsupported store or malformed metadata must
      // not lock employees out of attendance or destroy their saved session.
      return null;
    }
  }

  Future<AppUpdate?> _check() async {
    final app = await _readInstalled();
    if (app == null) return null;
    final response = await _dio.get<dynamic>(
      '${AppConfig.mobileApiBaseUrl}/version/',
      queryParameters: {
        'platform': app.platform,
        'version': app.version,
        'build_number': app.buildNumber
      },
    );
    if (response.data is! Map<String, dynamic>) return null;
    final update = AppUpdate.fromJson(response.data, app);
    if (update == null) return null;
    final available =
        await (_checkStore?.call(app, update) ?? _storeAvailable(app, update));
    return available ? update : null;
  }

  Future<bool> _storeAvailable(InstalledApp app, AppUpdate update) async {
    if (app.platform == 'android') {
      final info = await InAppUpdate.checkForUpdate();
      return info.packageName == app.packageName &&
          info.updateAvailability == UpdateAvailability.updateAvailable &&
          (info.availableVersionCode ?? 0) >= update.minimumBuild!;
    }
    final id =
        RegExp(r'/id([0-9]+)/?$').firstMatch(update.storeUrl.path)?.group(1);
    final pathCountry = update.storeUrl.pathSegments.isEmpty
        ? null
        : update.storeUrl.pathSegments.first;
    // Do not assume every iPhone uses the storefront from the admin's URL.
    final deviceCountry = app.countryCode;
    final country = (deviceCountry != null &&
                RegExp(r'^[a-zA-Z]{2}$').hasMatch(deviceCountry)
            ? deviceCountry
            : pathCountry)
        ?.toLowerCase();
    if (id == null ||
        country == null ||
        !RegExp(r'^[a-z]{2}$').hasMatch(country)) {
      return false;
    }
    final response = await _dio.get<dynamic>('https://itunes.apple.com/lookup',
        queryParameters: {'id': id, 'country': country},
        options: Options(headers: {'Cache-Control': 'no-cache'}));
    final data =
        response.data is String ? jsonDecode(response.data) : response.data;
    if (data is! Map || data['results'] is! List) return false;
    for (final result in data['results'] as List) {
      if (result is! Map ||
          result['bundleId'] != app.packageName ||
          '${result['trackId']}' != id) {
        continue;
      }
      final version = parseVersion('${result['version'] ?? ''}');
      final minimum = parseVersion(update.minimumVersion!)!;
      final minimumOs = parseVersion('${result['minimumOsVersion'] ?? ''}');
      final installedOs = parseVersion(app.osVersion ?? '');
      // A store listing alone is insufficient if this iPhone cannot install it.
      if (minimumOs == null ||
          installedOs == null ||
          compareVersions(installedOs, minimumOs) < 0) {
        return false;
      }
      return version != null && compareVersions(version, minimum) >= 0;
    }
    return false;
  }
}
