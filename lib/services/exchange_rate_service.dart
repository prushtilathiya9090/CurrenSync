import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ExchangeRateService {

  static String get _apiKey => dotenv.env['API_KEY'] ?? '';

  static String get _primaryUrl =>
      'https://v6.exchangerate-api.com/v6/$_apiKey/latest/USD';

  static const String _fallbackUrl =
      'https://api.frankfurter.app/latest?from=USD';

  static Future<Map<String, double>> fetchRates() async {
    try {
      final response = await http.get(Uri.parse(_primaryUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final rates = Map<String, double>.from(
          (data['rates'] as Map)
              .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
        );

        return rates;
      }
    } catch (_) {}

    // Fallback
    try {
      final response = await http.get(Uri.parse(_fallbackUrl)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
        );
        rates['USD'] = 1.0;
        return rates;
      }
    } catch (_) {}

    // Return mock rates if both fail
    return _getMockRates();
  }

  static Map<String, double> _getMockRates() {
    return {
      'USD': 1.0, 'EUR': 0.92, 'GBP': 0.79, 'JPY': 149.50, 'AUD': 1.53,
      'CAD': 1.36, 'CHF': 0.89, 'CNY': 7.24, 'INR': 83.12, 'KRW': 1325.0,
      'SGD': 1.34, 'HKD': 7.82, 'NOK': 10.56, 'SEK': 10.42, 'DKK': 6.89,
      'NZD': 1.63, 'MXN': 17.15, 'BRL': 4.97, 'ZAR': 18.63, 'RUB': 92.5,
      'TRY': 32.45, 'AED': 3.67, 'SAR': 3.75, 'THB': 35.1, 'IDR': 15650.0,
      'MYR': 4.72, 'PHP': 56.45, 'PKR': 279.0, 'EGP': 30.9, 'NGN': 1485.0,
      'KES': 130.5, 'CLP': 895.0, 'COP': 3920.0, 'ARS': 850.0, 'CZK': 22.8,
      'HUF': 354.0, 'PLN': 4.02, 'ILS': 3.72, 'QAR': 3.64, 'KWD': 0.307,
      'BHD': 0.377, 'OMR': 0.385, 'JOD': 0.709, 'LKR': 321.5, 'BGN': 1.80,
      'UAH': 38.0, 'GHS': 12.5, 'PEN': 3.72, 'RON': 4.58,
    };
  }

  static List<double> generateMockHistory(double currentRate) {
    final rand = Random();
    List<double> history = [];
    double rate = currentRate * (0.95 + rand.nextDouble() * 0.1);
    for (int i = 6; i >= 0; i--) {
      rate = rate * (0.99 + rand.nextDouble() * 0.02);
      history.add(rate);
    }
    history[history.length - 1] = currentRate;
    return history;
  }
}
