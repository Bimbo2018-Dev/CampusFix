import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ReportImageResult {
  const ReportImageResult({
    required this.name,
    required this.bytes,
    required this.dataUrl,
  });

  final String name;
  final Uint8List bytes;
  final String dataUrl;
}

class ReportImageHelper {
  static const maxStoredBytes = 480 * 1024;
  static const maxDimension = 960;
  static const minDimension = 480;
  static const jpegQuality = 72;
  static const _qualitySteps = [jpegQuality, 64, 56, 48];
  static final ImagePicker _picker = ImagePicker();

  static Future<ReportImageResult?> pickAndPrepareImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_shouldUseFilePicker) {
      return _pickWithFilePicker();
    }

    final file = await _picker.pickImage(
      source: source,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: jpegQuality,
      requestFullMetadata: false,
    );

    if (file == null) {
      return null;
    }

    final rawBytes = await _readBytes(file);
    final preparedBytes = _prepareBytes(rawBytes);
    if (preparedBytes.length > maxStoredBytes) {
      throw const ReportImageTooLargeException();
    }

    return ReportImageResult(
      name: file.name,
      bytes: preparedBytes,
      dataUrl: toDataUrl(preparedBytes),
    );
  }

  static Future<ReportImageResult?> _pickWithFilePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      compressionQuality: jpegQuality,
      cancelUploadOnWindowBlur: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final rawBytes = file.bytes;
    if (rawBytes == null || rawBytes.isEmpty) {
      throw const ReportImageReadException();
    }

    final preparedBytes = _prepareBytes(rawBytes);
    if (preparedBytes.length > maxStoredBytes) {
      throw const ReportImageTooLargeException();
    }

    return ReportImageResult(
      name: file.name,
      bytes: preparedBytes,
      dataUrl: toDataUrl(preparedBytes),
    );
  }

  static Uint8List? bytesFromDataUrl(String? dataUrl) {
    if (dataUrl == null || dataUrl.isEmpty) {
      return null;
    }

    final commaIndex = dataUrl.indexOf(',');
    if (!dataUrl.startsWith('data:image/') || commaIndex == -1) {
      return null;
    }

    try {
      return base64Decode(dataUrl.substring(commaIndex + 1));
    } on FormatException {
      return null;
    }
  }

  static String? networkImageUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    return uri.scheme == 'https' || uri.scheme == 'http' ? value : null;
  }

  static String toDataUrl(Uint8List bytes) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static Future<Uint8List> _readBytes(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const ReportImageReadException();
      }
      return bytes;
    } on ReportImageReadException {
      rethrow;
    } catch (_) {
      throw const ReportImageReadException();
    }
  }

  static Uint8List _prepareBytes(Uint8List rawBytes) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (_) {
      throw const ReportImageUnsupportedException();
    }

    if (decoded == null) {
      throw const ReportImageUnsupportedException();
    }

    final oriented = img.bakeOrientation(decoded);
    Uint8List? bestAttempt;
    var currentDimension = maxDimension;

    try {
      while (currentDimension >= minDimension) {
        final resized = _resizeIfNeeded(oriented, currentDimension);
        for (final quality in _qualitySteps) {
          final encoded = Uint8List.fromList(
            img.encodeJpg(resized, quality: quality),
          );
          if (bestAttempt == null || encoded.length < bestAttempt.length) {
            bestAttempt = encoded;
          }
          if (encoded.length <= maxStoredBytes) {
            return encoded;
          }
        }
        currentDimension = (currentDimension * 0.78).round();
      }
    } catch (_) {
      throw const ReportImageReadException();
    }

    if (bestAttempt == null) {
      throw const ReportImageReadException();
    }
    return bestAttempt;
  }

  static img.Image _resizeIfNeeded(img.Image source, int maxSide) {
    final longestSide =
        source.width > source.height ? source.width : source.height;
    if (longestSide <= maxSide) {
      return source;
    }

    if (source.width >= source.height) {
      return img.copyResize(source, width: maxSide);
    }
    return img.copyResize(source, height: maxSide);
  }

  static bool get _shouldUseFilePicker {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }
}

class ReportImageTooLargeException implements Exception {
  const ReportImageTooLargeException();
}

class ReportImageReadException implements Exception {
  const ReportImageReadException();
}

class ReportImageUnsupportedException implements Exception {
  const ReportImageUnsupportedException();
}
