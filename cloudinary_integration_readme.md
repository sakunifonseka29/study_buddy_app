# Cloudinary Integration for Study Buddy App

This document explains how the Cloudinary integration works in the Study Buddy app and how to test it.

## Overview

The app uses Cloudinary for two main purposes:

1. Storing user profile pictures
2. Storing study materials in the Library section

## Components

1. **CloudinaryService**: Handles all Cloudinary API operations

   - Located at: `lib/Service/cloudinaryService.dart`
   - Provides methods to upload and delete files

2. **API Keys**: Configuration for Cloudinary credentials

   - Located at: `lib/config/api_keys.dart`
   - Contains the cloud name, API key, and API secret

3. **Library Page**: UI for uploading and viewing study materials

   - Located at: `lib/Views/library_page.dart`
   - Allows users to upload documents by subject

4. **Profile Page**: UI for uploading profile pictures
   - Located at: `lib/Views/profile_page.dart`
   - Includes a "Test Cloudinary Connection" button

## Setup Instructions

See `lib/config/cloudinary_setup.md` for detailed setup instructions.

## Testing the Integration

1. **Test Connection**:

   - Go to your profile page
   - Tap the "Test Cloudinary Connection" button
   - A dialog will appear showing if the connection is successful

2. **Upload Profile Picture**:

   - Go to your profile page
   - Tap on your profile picture or the camera icon
   - Select a photo from your gallery or take a new one
   - If successful, your profile picture will update

3. **Upload Study Materials**:
   - Go to the Library page from the bottom navigation or dashboard
   - Select a subject from the dropdown
   - Tap the floating action button to upload a document
   - Choose a document file (PDF, DOC, etc.)
   - If successful, the document will appear in the list

## Troubleshooting

If you encounter issues with Cloudinary:

1. Check your Cloudinary credentials in `lib/config/api_keys.dart`
2. Ensure you have internet connectivity
3. Verify that the file types you're trying to upload are supported
4. Check console logs for specific error messages

## Supported File Types

- **Images**: JPEG, PNG, GIF
- **Documents**: PDF, DOC, DOCX, PPT, PPTX, TXT, RTF
