/*
 * Cloudinary Service
 * 
 * This service handles file uploads to Cloudinary, including profile images and study materials.
 * 
 * Before using this service, ensure you have:
 * 1. Created a Cloudinary account
 * 2. Updated the API keys in config/api_keys.dart with your Cloudinary credentials
 * 3. Added cloudinary_sdk package to pubspec.yaml
 *
 * Usage:
 * - For profile images: Use UserService.uploadProfileImage method
 * - For study materials: Use the LibraryPage file upload functionality
 */

import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:study_buddy_app/config/api_keys.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class CloudinaryService {
  late final Cloudinary _cloudinary;

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
    'application/vnd.openxmlformats-officedocument.presentationml.presentation', // PPTX
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // XLSX
    'text/plain', // TXT
    'application/rtf', // RTF
  ];
  CloudinaryService() {
    _cloudinary = Cloudinary.full(
      apiKey: ApiKeys.cloudinaryApiKey,
      apiSecret: ApiKeys.cloudinaryApiSecret,
      cloudName: ApiKeys.cloudinaryCloudName,
    );
  }

  /// Upload an image or document file to Cloudinary
  /// Returns the URL of the uploaded file
  Future<String?> uploadFile({
    required File file,
    required String userId,
    String? folder,
    bool isProfileImage = false,
  }) async {
    try {
      // Get file info
      // Note: We get the filename for logging/future use but use uniqueFileName for upload
      final fileName = path.basename(file.path); // Keep for reference
      final mimeType = lookupMimeType(file.path);

      // Validate file type
      if (!_isSupportedFileType(mimeType)) {
        throw Exception('Unsupported file type: $mimeType');
      }

      // Determine if it's an image or document
      final resourceType = _getResourceType(mimeType);

      // Determine the folder to upload to
      final uploadFolder =
          isProfileImage
              ? 'profile_images'
              : folder ?? _determineFolder(mimeType);

      // Create a unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${userId}_$timestamp';

      // Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        filePath: file.path,
        resourceType: resourceType,
        folder: uploadFolder,
        fileName: uniqueFileName,
        progressCallback: (count, total) {
          // Optional: You can implement progress tracking here
        },
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Delete a file from Cloudinary by URL or public ID
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extract public ID from URL
      final Uri uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find the upload segment index
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        throw Exception('Invalid Cloudinary URL format');
      }

      // Extract folder and filename (public ID)
      final folder = pathSegments[uploadIndex + 1];
      final filename = pathSegments[uploadIndex + 2].split('.').first;
      final publicId = '$folder/$filename';

      // Delete from Cloudinary
      final response = await _cloudinary.deleteFile(
        publicId: publicId,
        resourceType: CloudinaryResourceType.image, // Change if needed
      );

      return response.isSuccessful;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// Check if the file type is supported
  bool _isSupportedFileType(String? mimeType) {
    if (mimeType == null) return false;
    return supportedImageTypes.contains(mimeType) ||
        supportedDocumentTypes.contains(mimeType);
  }

  /// Determine CloudinaryResourceType based on MIME type
  CloudinaryResourceType _getResourceType(String? mimeType) {
    if (mimeType == null) return CloudinaryResourceType.raw;

    if (supportedImageTypes.contains(mimeType)) {
      return CloudinaryResourceType.image;
    } else if (supportedDocumentTypes.contains(mimeType)) {
      return CloudinaryResourceType.raw;
    }

    return CloudinaryResourceType.raw;
  }

  /// Determine folder based on MIME type
  String _determineFolder(String? mimeType) {
    if (mimeType == null) return 'other';

    if (mimeType.startsWith('image/')) return 'images';
    if (mimeType == 'application/pdf') return 'pdfs';
    if (mimeType.contains('document') || mimeType.contains('word'))
      return 'documents';
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint'))
      return 'presentations';
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel'))
      return 'spreadsheets';

    return 'other';
  }
}
