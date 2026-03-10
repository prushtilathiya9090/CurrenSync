import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../services/exchange_rate_service.dart';

class CurrencyProvider extends ChangeNotifier {
  List<Currency> _allCurrencies = [];
  List<Currency> _favoriteCurrencies = [];
  Map<String, double> _rates = {};
  String _baseCurrency = 'USD';
  String _targetCurrency = 'EUR';
  double _amount = 1.0;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime? _lastUpdated;
  List<String> _favorites = [];
  List<Map<String, dynamic>> _conversionHistory = [];
  Timer? _refreshTimer;

  List<Currency> get allCurrencies => _allCurrencies;
  List<Currency> get favoriteCurrencies => _favoriteCurrencies;
  Map<String, double> get rates => _rates;
  String get baseCurrency => _baseCurrency;
  String get targetCurrency => _targetCurrency;
  double get amount => _amount;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  List<String> get favorites => _favorites;
  List<Map<String, dynamic>> get conversionHistory => _conversionHistory;

  double get convertedAmount {
    if (_rates.isEmpty) return 0;
    final baseRate = _rates[_baseCurrency] ?? 1.0;
    final targetRate = _rates[_targetCurrency] ?? 1.0;
    return (_amount / baseRate) * targetRate;
  }

  double get exchangeRate {
    if (_rates.isEmpty) return 0;
    final baseRate = _rates[_baseCurrency] ?? 1.0;
    final targetRate = _rates[_targetCurrency] ?? 1.0;
    return targetRate / baseRate;
  }

  CurrencyProvider() {
    _allCurrencies = Currency.getAllCurrencies();
    _init();
  }

  Future<void> _init() async {
    await _loadPreferences();
    await fetchRates();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      fetchRates();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _baseCurrency = prefs.getString('baseCurrency') ?? 'USD';
    _targetCurrency = prefs.getString('targetCurrency') ?? 'EUR';
    _amount = prefs.getDouble('amount') ?? 1.0;
    _favorites = prefs.getStringList('favorites') ?? ['USD', 'EUR', 'GBP', 'JPY', 'INR'];
    _updateFavorites();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseCurrency', _baseCurrency);
    await prefs.setString('targetCurrency', _targetCurrency);
    await prefs.setDouble('amount', _amount);
    await prefs.setStringList('favorites', _favorites);
  }

  Future<void> fetchRates() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _rates = await ExchangeRateService.fetchRates();
      for (var currency in _allCurrencies) {
        currency.rate = _rates[currency.code] ?? 1.0;
      }
      _lastUpdated = DateTime.now();
      _hasError = false;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to fetch rates. Using cached data.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBaseCurrency(String code) {
    _baseCurrency = code;
    _savePreferences();
    notifyListeners();
  }

  void setTargetCurrency(String code) {
    _targetCurrency = code;
    _savePreferences();
    notifyListeners();
  }

  void setAmount(double amount) {
    _amount = amount;
    _savePreferences();
    notifyListeners();
  }

  void swapCurrencies() {
    final temp = _baseCurrency;
    _baseCurrency = _targetCurrency;
    _targetCurrency = temp;
    _savePreferences();
    notifyListeners();
  }

  void toggleFavorite(String code) {
    if (_favorites.contains(code)) {
      _favorites.remove(code);
    } else {
      _favorites.add(code);
    }
    _updateFavorites();
    _savePreferences();
    notifyListeners();
  }

  bool isFavorite(String code) => _favorites.contains(code);

  void _updateFavorites() {
    _favoriteCurrencies = _allCurrencies
        .where((c) => _favorites.contains(c.code))
        .toList();
  }

  void clearHistory() {
    _conversionHistory.clear();
    _deletedItem = null;
    _deletedIndex = null;
    notifyListeners();
  }

  Map<String, dynamic>? _deletedItem;
  int? _deletedIndex;

  void removeHistoryAt(int index) {
    if (index < 0 || index >= _conversionHistory.length) return;
    _deletedItem = _conversionHistory[index];
    _deletedIndex = index;
    _conversionHistory.removeAt(index);
    notifyListeners();
  }

  void undoDelete() {
    if (_deletedItem != null && _deletedIndex != null) {
      final idx = _deletedIndex!.clamp(0, _conversionHistory.length);
      _conversionHistory.insert(idx, _deletedItem!);
      _deletedItem = null;
      _deletedIndex = null;
      notifyListeners();
    }
  }

  void addToHistory(String from, String to, double amount, double result) {
    _conversionHistory.insert(0, {
      'from': from,
      'to': to,
      'amount': amount,
      'result': result,
      'rate': exchangeRate,
      'timestamp': DateTime.now(),
    });
    if (_conversionHistory.length > 50) {
      _conversionHistory = _conversionHistory.sublist(0, 50);
    }
    notifyListeners();
  }

  Currency? getCurrency(String code) {
    try {
      return _allCurrencies.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  List<Currency> searchCurrencies(String query) {
    if (query.isEmpty) return _allCurrencies;
    final q = query.toLowerCase();
    return _allCurrencies.where((c) =>
      c.code.toLowerCase().contains(q) ||
      c.name.toLowerCase().contains(q) ||
      c.country.toLowerCase().contains(q)
    ).toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}