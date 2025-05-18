// API Configuration for remote endpoints
class APIConfig {
  // Default to local emulator address for Android
  static String get baseUrl {
    // Get this value from environment variables, build configuration, etc.
    // For example, could be set during build process
    const bool isProduction = bool.fromEnvironment(
      'PROD_MODE',
      defaultValue: false,
    );

    if (isProduction) {
      return 'https://your-production-server.com';
    } else {
      // Local development:
      // - Use 10.0.2.2 for Android emulator (maps to host's localhost)
      // - Use localhost for web
      // - Use machine's IP address for physical devices
      return 'http://10.0.2.2:5051';
    }
  }
}
