import 'dart:convert';
import 'package:http/http.dart' as http;

/// API base URL from Codemagic env (API_URL) or default.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://eczemacare.onrender.com',
);

/// Fetches data from the EczemaCare API.
/// Returns the message string on success, or null on failure.
Future<String?> fetchData() async {
  final response = await http.get(Uri.parse('$apiBaseUrl/'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['message'] as String?;
  }
  return null;
}
