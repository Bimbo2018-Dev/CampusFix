import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CampusFixUpdateInfo {
  const CampusFixUpdateInfo({
    required this.signature,
    required this.downloadUrl,
    this.generatedAt,
    this.size,
  });

  final String signature;
  final Uri downloadUrl;
  final String? generatedAt;
  final int? size;
}

class CampusFixUpdateChecker {
  static const installedAndroidSignature = String.fromEnvironment(
    'CAMPUSFIX_ANDROID_BUILD_SIGNATURE',
  );
  static const androidUpdateMetadataUrl = String.fromEnvironment(
    'CAMPUSFIX_ANDROID_UPDATE_METADATA_URL',
  );

  static bool get supportsAndroidUpdateChecks {
    return !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        installedAndroidSignature.isNotEmpty;
  }

  static Future<CampusFixUpdateInfo?> checkForAndroidUpdate({
    required String apiBaseUrl,
    http.Client? client,
  }) async {
    if (!supportsAndroidUpdateChecks) {
      return null;
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    try {
      final metadataUrl = androidUpdateMetadataUrl.isNotEmpty
          ? Uri.parse(androidUpdateMetadataUrl)
          : _webServerUri(
              apiBaseUrl, '/downloads/campusfix_android_version.json');
      final response = await httpClient.get(metadataUrl, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }

      final data = Map<String, dynamic>.from(decoded);
      final latestSignature = data['signature'] as String? ?? '';
      if (latestSignature.isEmpty ||
          latestSignature == installedAndroidSignature) {
        return null;
      }

      return CampusFixUpdateInfo(
        signature: latestSignature,
        downloadUrl: _downloadUri(
          apiBaseUrl,
          data['downloadPath'] as String?,
        ),
        generatedAt: data['generatedAt'] as String?,
        size: data['size'] is int ? data['size'] as int : null,
      );
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } on http.ClientException {
      return null;
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<bool> openAndroidUpdate(
    CampusFixUpdateInfo updateInfo,
  ) async {
    return launchUrl(
      updateInfo.downloadUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  static Uri _webServerUri(String apiBaseUrl, String path) {
    final apiUri = Uri.tryParse(apiBaseUrl);
    if (apiUri == null || apiUri.host.isEmpty) {
      return Uri.parse('http://127.0.0.1:8791$path');
    }

    return apiUri.replace(
      port: 8791,
      path: path,
      query: null,
      fragment: null,
    );
  }

  static Uri _downloadUri(String apiBaseUrl, String? downloadPath) {
    if (downloadPath != null && downloadPath.isNotEmpty) {
      final absolute = Uri.tryParse(downloadPath);
      if (absolute != null && absolute.hasScheme && absolute.host.isNotEmpty) {
        return absolute;
      }
      if (downloadPath.startsWith('/')) {
        return _webServerUri(apiBaseUrl, downloadPath);
      }
    }

    return _webServerUri(apiBaseUrl, '/downloads/CampusFix.apk');
  }
}
