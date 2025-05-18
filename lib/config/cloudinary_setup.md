# Setting Up Cloudinary for Study Buddy App

This document guides you through the process of setting up Cloudinary for the Study Buddy app.

## Getting Cloudinary Credentials

1. **Create a Cloudinary Account**:

   - Go to [Cloudinary's website](https://cloudinary.com/)
   - Sign up for a free account

2. **Find Your Credentials**:
   - After signing up and logging in, go to your dashboard
   - You will see your Cloud Name, API Key, and API Secret
   - These are the credentials you need for the app

## Setting Credentials in the App

### Option 1: Environment Variables (Recommended for Development)

Set the following environment variables on your development machine:

```bash
# On Windows PowerShell:
$env:CLOUDINARY_CLOUD_NAME="your_cloud_name"
$env:CLOUDINARY_API_KEY="your_api_key"
$env:CLOUDINARY_API_SECRET="your_api_secret"

# On Windows Command Prompt:
set CLOUDINARY_CLOUD_NAME=your_cloud_name
set CLOUDINARY_API_KEY=your_api_key
set CLOUDINARY_API_SECRET=your_api_secret

# On macOS/Linux:
export CLOUDINARY_CLOUD_NAME=your_cloud_name
export CLOUDINARY_API_KEY=your_api_key
export CLOUDINARY_API_SECRET=your_api_secret
```

### Option 2: Direct Modification (Not Recommended for Production)

If you're just testing locally, you can modify the `api_keys.dart` file directly:

1. Open `lib/config/api_keys.dart`
2. Replace the default values with your actual Cloudinary credentials:

```dart
static String get cloudinaryCloudName => _getEnvOrValue('CLOUDINARY_CLOUD_NAME', 'your_cloud_name');
static String get cloudinaryApiKey => _getEnvOrValue('CLOUDINARY_API_KEY', 'your_api_key');
static String get cloudinaryApiSecret => _getEnvOrValue('CLOUDINARY_API_SECRET', 'your_api_secret');
```

## Security Note

- Never commit your actual API keys to version control
- For production, use secure environment variables or a secrets management service
- Consider using Flutter's environment variables or a secure storage solution for mobile apps

## Testing Your Setup

After setting up your credentials:

1. Try uploading a profile picture in the app
2. Check the Library page and try uploading a document
3. Verify that uploads appear in your Cloudinary dashboard

If you encounter issues, check the console logs for specific error messages related to Cloudinary.
