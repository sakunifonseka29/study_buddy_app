import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class MediaUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Supported file types
  static const List<String> supportedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
  ];

  static const List<String> supportedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  static const List<String> supportedVideoTypes = [
    'video/mp4',
    'video/quicktime',
  ];

  Future<String?> uploadMedia({
    required File file,
    required String userId,
    String? folderName,
  }) async {
    try {
      // Get file info
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path);

      // Validate file type
      if (!_isSupportedMediaType(mimeType)) {
        throw Exception('Unsupported file type: $mimeType');
      }

      // Determine storage path
      final storagePath = _getStoragePath(
        userId: userId,
        fileName: fileName,
        mimeType: mimeType,
        folderName: folderName,
      );

      // Upload file
      final uploadTask = _storage.ref(storagePath).putFile(file);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  Future<void> deleteMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting media: $e');
    }
  }

  String _getStoragePath({
    required String userId,
    required String fileName,
    required String? mimeType,
    String? folderName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = path.extension(fileName);
    final newFileName = '${userId}_$timestamp$fileExtension';

    if (mimeType?.startsWith('image/') ?? false) {
      return '${folderName ?? 'profile_images'}/$newFileName';
    } else if (mimeType?.startsWith('video/') ?? false) {
      return '${folderName ?? 'videos'}/$newFileName';
    } else {
      return '${folderName ?? 'documents'}/$newFileName';
    }
  }

  bool _isSupportedMediaType(String? mimeType) {
    if (mimeType == null) return false;
    return supportedImageTypes.contains(mimeType) ||
        supportedDocumentTypes.contains(mimeType) ||
        supportedVideoTypes.contains(mimeType);
  }

  String getFileType(String? mimeType) {
    if (mimeType == null) return 'unknown';
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('application/')) return 'document';
    return 'unknown';
  }
}
