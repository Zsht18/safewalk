import 'dart:convert';

import 'package:http/http.dart' as http;

class PhilSmsConfig {
  const PhilSmsConfig({
    required this.endpoint,
    required this.apiKey,
    this.senderId = 'SAFEWALK',
  });

  final String endpoint;
  final String apiKey;
  final String senderId;

  bool get isConfigured =>
      endpoint.isNotEmpty &&
      apiKey.isNotEmpty &&
      !endpoint.startsWith('PUT_') &&
      !apiKey.startsWith('PUT_');
}

class PhilSmsMessage {
  const PhilSmsMessage({required this.recipient, required this.message});

  final String recipient;
  final String message;

  Map<String, dynamic> toPayload(String senderId) {
    return {
      'recipient': recipient,
      'message': message,
      'sender_id': senderId,
    };
  }
}

class PhilSmsService {
  const PhilSmsService(this.config);

  final PhilSmsConfig config;

  // API is ready: this validates config and payload shape, but call only works
  // after real endpoint/key are provided.
  Future<void> send(PhilSmsMessage sms) async {
    if (!config.isConfigured) {
      throw Exception('PhilSMS is not configured yet. Add endpoint and API key in PhilSmsConfig.');
    }

    final endpointUri = _normalizeEndpoint(config.endpoint);
    final firstResponse = await http.post(
      endpointUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
        'api_token': config.apiKey,
        'X-Sender-Id': config.senderId,
      },
      body: jsonEncode(sms.toPayload(config.senderId)),
    );

    if (firstResponse.statusCode >= 400) {
      final bodyLower = firstResponse.body.toLowerCase();
      final senderRejected = bodyLower.contains('sender id') && bodyLower.contains('not authorized');

      if (senderRejected) {
        final fallbackResponse = await http.post(
          endpointUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
            'api_token': config.apiKey,
          },
          body: jsonEncode({
            'recipient': sms.recipient,
            'message': sms.message,
          }),
        );

        if (fallbackResponse.statusCode >= 400) {
          throw Exception(_buildErrorMessage(fallbackResponse.statusCode, fallbackResponse.body));
        }
        return;
      }

      throw Exception(_buildErrorMessage(firstResponse.statusCode, firstResponse.body));
    }

    final bodyLower = firstResponse.body.toLowerCase();
    if (bodyLower.contains('<html') || bodyLower.contains('<!doctype html')) {
      throw Exception(
        'PhilSMS endpoint returned HTML. Use the API route (for example /api/v3/sms/send), not the dashboard page URL.',
      );
    }
  }

  Uri _normalizeEndpoint(String raw) {
    final parsed = Uri.parse(raw.trim());
    final normalizedPath = parsed.path.endsWith('/api/v3') || parsed.path.endsWith('/api/v3/')
        ? '${parsed.path.replaceAll(RegExp(r'/+$'), '')}/sms/send'
        : parsed.path;

    return parsed.replace(path: normalizedPath);
  }

  String _buildErrorMessage(int statusCode, String body) {
    final bodyLower = body.toLowerCase();
    if (bodyLower.contains('<html') || bodyLower.contains('<!doctype html')) {
      return 'PhilSMS endpoint looks incorrect (HTML response). Point endpoint to API path like /api/v3/sms/send.';
    }

    var trimmed = body.trim();
    if (trimmed.length > 250) {
      trimmed = '${trimmed.substring(0, 250)}...';
    }
    return 'PhilSMS request failed ($statusCode): $trimmed';
  }
}
