import 'package:flutter/foundation.dart';
import 'package:study_buddy_app/config/api_keys.dart';

/// Service to check if Cloudinary is properly configured
class CloudinarySetupService {
  /// Check if Cloudinary is properly configured
  static bool isCloudinaryConfigured() {
    // Get the Cloudinary credentials being used
    final cloudName = ApiKeys.cloudinaryCloudName;
    final apiKey = ApiKeys.cloudinaryApiKey;
    final apiSecret = ApiKeys.cloudinaryApiSecret;

    // Check if credentials are the default/placeholder values
    bool usingDefaultCredentials =
        cloudName == 'study_buddy_app' &&
        apiKey == '123456789012345' &&
        apiSecret == 'abcdefghijklmnopqrstuvwxyz12345';

    if (usingDefaultCredentials) {
      debugPrint(
        '⚠️ WARNING: Using default Cloudinary credentials. Set up proper credentials for production use.',
      );
      debugPrint(
        '📝 See lib/config/cloudinary_setup.md for setup instructions.',
      );
      return false;
    }

    debugPrint('✅ Cloudinary configuration detected: $cloudName');
    return true;
  }
}
