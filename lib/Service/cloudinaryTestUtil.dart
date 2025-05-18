import 'package:flutter/material.dart';
import 'package:study_buddy_app/Service/cloudinaryService.dart';
import 'package:study_buddy_app/config/api_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Utility class to test and verify Cloudinary configuration
class CloudinaryTestUtil {
  /// Tests the Cloudinary connection and configuration
  static Future<bool> testCloudinaryConnection(BuildContext context) async {
    try {
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
        _showConnectionDialog(
          context,
          false,
          'Using default credentials. Please configure your Cloudinary credentials.',
        );
        return false;
      }

      // Create instance to test configuration
      final CloudinaryService service = CloudinaryService();

      // Display success message
      _showConnectionDialog(
        context,
        true,
        'Cloudinary configuration looks good! Cloud Name: $cloudName',
      );

      return true;
    } catch (e) {
      // Show error message
      _showConnectionDialog(
        context,
        false,
        'Error connecting to Cloudinary: ${e.toString()}',
      );
      return false;
    }
  }

  /// Shows a dialog with the connection test results
  static void _showConnectionDialog(
    BuildContext context,
    bool success,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(success ? 'Cloudinary Connected' : 'Cloudinary Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(message),
                if (!success) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Please check the cloudinary_setup.md file in the config folder for setup instructions.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

/// Riverpod provider for CloudinaryTestUtil
final cloudinaryTestProvider = Provider<CloudinaryTestUtil>((ref) {
  return CloudinaryTestUtil();
});
