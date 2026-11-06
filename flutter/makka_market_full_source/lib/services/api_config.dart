/// Set this to the public HTTPS URL of the deployed Laravel API.
/// Android emulator can use http://10.0.2.2:8000/api for a local host server.
/// A physical phone must use the computer/server LAN IP or public domain.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'MAKKA_API_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
