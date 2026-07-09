import 'dart:io';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class UploadToFireStorage {
  Future<XFile?> compressImage(XFile file) async {
    try {
      final fileToCompress = File(file.path);
      if (!await fileToCompress.exists()) {
        debugPrint('Source file for compression does not exist: ${file.path}');
        return file;
      }

      final fileSize = await fileToCompress.length();

      int quality = 85;
      int maxWidth = 1024;
      int maxHeight = 1024;

      if (fileSize > 5 * 1024 * 1024) {
        quality = 45;
        maxWidth = 800;
        maxHeight = 800;
      } else if (fileSize > 2 * 1024 * 1024) {
        quality = 55;
        maxWidth = 900;
        maxHeight = 900;
      } else if (fileSize > 1 * 1024 * 1024) {
        quality = 65;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final lastDotIndex = file.path.lastIndexOf('.');
      if (lastDotIndex == -1) return file;

      final compressedPath =
          '${file.path.substring(0, lastDotIndex)}_compressed_$timestamp.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        compressedPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: true,
      );

      if (compressedFile != null && await File(compressedFile.path).exists()) {
        return compressedFile;
      }
      return file;
    } catch (e) {
      debugPrint('Compression error: $e');
      return file;
    }
  }

  Future<XFile?> compressToPng(XFile file) async {
    try {
      final fileToCompress = File(file.path);
      if (!await fileToCompress.exists()) return file;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final lastDotIndex = file.path.lastIndexOf('.');
      if (lastDotIndex == -1) return file;

      final pngPath =
          '${file.path.substring(0, lastDotIndex)}_fallback_$timestamp.png';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        pngPath,
        quality: 80,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.png,
        keepExif: false,
      );

      if (compressedFile != null && await File(compressedFile.path).exists()) {
        final compressedSize = await File(compressedFile.path).length();
        debugPrint('PNG compressed file size: $compressedSize bytes');
        return compressedFile;
      }

      return file;
    } catch (e) {
      debugPrint('PNG compression error: $e');
      return file;
    }
  }

  Future<String?> uploadFile(XFile file, String storagePath) async {
    final ext = file.path.split('.').last.split('?').first.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

    if (!isImage) {
      // For non-images (PDF, Doc, etc.), skip compression and upload directly
      return _performUpload(
        file,
        storagePath,
        null,
        extension: ext,
        contentType: _getContentType(ext),
      );
    }

    XFile? compressedFile;
    try {
      compressedFile = await compressImage(file);
      final finalFile = compressedFile ?? file;
      final finalExt = finalFile.path
          .split('.')
          .last
          .split('?')
          .first
          .toLowerCase();

      final fileToUpload = File(finalFile.path);
      if (!await fileToUpload.exists()) {
        debugPrint(
          'Upload error: Target file not found at ${finalFile.path}. Falling back to original.',
        );
        final originalFile = File(file.path);
        if (!await originalFile.exists()) {
          throw Exception('The selected file could not be found.');
        }
        final origExt = file.path
            .split('.')
            .last
            .split('?')
            .first
            .toLowerCase();
        return _performUpload(
          file,
          storagePath,
          null,
          extension: origExt,
          contentType: _getContentType(origExt),
        );
      }

      return _performUpload(
        finalFile,
        storagePath,
        compressedFile,
        extension: finalExt,
        contentType: _getContentType(finalExt),
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'unknown':
          if (e.message?.contains('Message too long') == true) {
            errorMessage =
                'Image file is corrupted or in an unsupported format. Please try a different image.';
          } else {
            errorMessage =
                'Upload failed due to an unknown error. Please try again.';
          }
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection and try again.';
          break;
        case 'quota-exceeded':
          errorMessage = 'Storage quota exceeded. Please try again later.';
          break;
        case 'unauthorized':
          errorMessage =
              'You are not authorized to upload files. Please log in again.';
          break;
        case 'cancelled':
          errorMessage = 'Upload was cancelled.';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message ?? 'Unknown error'}';
      }

      throw Exception(errorMessage);
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Upload timed out. The image might be too large or your connection is slow. Please try a smaller image.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      throw Exception(
        'Unexpected error during upload. Please try again with a different image.',
      );
    }
  }

  String _getContentType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String?> _performUpload(
    XFile finalFile,
    String storagePath,
    XFile? compressedFile, {
    String? extension,
    String? contentType,
  }) async {
    final file = File(finalFile.path);
    final fileSize = await file.length();

    // Only enforce size limit for images that we try to compress
    // For PDFs or other docs, we might want to allow slightly larger files if needed,
    // but 2MB is a reasonable general limit for now.
    if (fileSize > 5 * 1024 * 1024) {
      throw Exception(
        'File is too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Please select a file smaller than 5MB.',
      );
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString();
    final ext = extension ?? 'jpg';
    final fileName = 'file_${timestamp}_$randomSuffix.$ext';
    final ref = AppFireStorage.agentDocStorageRef
        .child(storagePath)
        .child(fileName);

    final metadata = SettableMetadata(
      contentType: contentType ?? 'image/jpeg',
      cacheControl: 'public, max-age=31536000',
    );
    final uploadTask = ref.putFile(file, metadata);
    const timeoutDuration = Duration(minutes: 3);

    final snapshot = await uploadTask.timeout(timeoutDuration);
    final downloadUrl = await snapshot.ref.getDownloadURL();

    try {
      if (compressedFile != null && compressedFile.path != finalFile.path) {
        if (await File(compressedFile.path).exists()) {
          await File(compressedFile.path).delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting temporary file: $e');
    }

    return downloadUrl;
  }
}
