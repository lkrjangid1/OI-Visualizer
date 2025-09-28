import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oi_visualizer/oi_visualizer.dart';

class OpenInterestApi {
  final String baseUrl;
  final http.Client _client;

  OpenInterestApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Future<TransformedData> getOpenInterest(String underlying) async {
    String identifier = underlying;
    if (identifier.endsWith(' - Weekly')) {
      identifier = identifier.replaceAll(' - Weekly', '');
    } else if (identifier.endsWith(' - Monthly')) {
      identifier = identifier.replaceAll(' - Monthly', '');
    }
    identifier = Uri.encodeComponent(identifier);

    final url = Uri.parse('$baseUrl/open-interest?identifier=$identifier');

    try {
      final response = await _client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return TransformedData.fromJson(json.decode(response.body));
      }

      throw Exception(
        'GET $url failed: ${response.statusCode} ${response.reasonPhrase}\n'
        'Body: ${response.body}',
      );
    } catch (e, s) {
      throw Exception('Error fetching open interest data: $e\n$s');
    }
  }

  Future<BuilderData> getBuilderData({
    required double? underlyingPrice,
    required double? targetUnderlyingPrice,
    required String? targetDateTimeISOString,
    required Map<String, double>? futuresPerExpiry,
    required List<ActiveOptionLeg>? optionLegs,
    required double? lotSize,
    required bool? isIndex,
  }) async {
    // Strong input validation before hitting server
    if ((optionLegs ?? []).isEmpty) {
      throw ArgumentError('optionLegs cannot be empty.');
    }
    if ((underlyingPrice ?? 0) <= 0 || (targetUnderlyingPrice ?? 0) <= 0) {
      throw ArgumentError('Prices must be > 0.');
    }
    if ((lotSize ?? 0) <= 0) {
      throw ArgumentError('lotSize must be > 0.');
    }

    // Build a clean JSON payload
    final payload = <String, dynamic>{
      "underlyingPrice": underlyingPrice,
      "targetUnderlyingPrice": targetUnderlyingPrice,
      "targetDateTimeISOString": targetDateTimeISOString,
      // Send an explicit map (server may rely on keys existing)
      "atmIVsPerExpiry": <String, double>{},
      "futuresPerExpiry": futuresPerExpiry,
      // Ensure JSON by mapping to toJson()
      "optionLegs": optionLegs?.map((e) => e.toJson()).toList(),
      "lotSize": lotSize,
      "isIndex": isIndex,
    };

    // Helpful client-side log (remove in prod)
    // ignore: avoid_print
    print('POST $baseUrl/builder\nPayload: ${jsonEncode(payload)}');

    try {
      final url = Uri.parse('$baseUrl/builder');
      final response = await _client
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BuilderData.fromJson(jsonData);
      }

      // Log full server response to see exact error and then fall back
      final err =
          'POST $url failed: ${response.statusCode} ${response.reasonPhrase}\n'
          'Body: ${response.body}';
      // ignore: avoid_print
      print(err);
      throw Exception(err);
    } catch (e, s) {
      // ignore: avoid_print
      print('Network/parse error: $e\n$s');
      throw Exception('$e\n$s');
    }
  }

  void dispose() {
    _client.close();
  }
}
