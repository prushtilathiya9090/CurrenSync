class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final String country;
  double rate;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.country,
    this.rate = 1.0,
  });

  static List<Currency> getAllCurrencies() {
    return [
      Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸', country: 'United States'),
      Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺', country: 'European Union'),
      Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧', country: 'United Kingdom'),
      Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵', country: 'Japan'),
      Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺', country: 'Australia'),
      Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦', country: 'Canada'),
      Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'Fr', flag: '🇨🇭', country: 'Switzerland'),
      Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳', country: 'China'),
      Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳', country: 'India'),
      Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷', country: 'South Korea'),
      Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬', country: 'Singapore'),
      Currency(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$', flag: '🇭🇰', country: 'Hong Kong'),
      Currency(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr', flag: '🇳🇴', country: 'Norway'),
      Currency(code: 'SEK', name: 'Swedish Krona', symbol: 'kr', flag: '🇸🇪', country: 'Sweden'),
      Currency(code: 'DKK', name: 'Danish Krone', symbol: 'kr', flag: '🇩🇰', country: 'Denmark'),
      Currency(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$', flag: '🇳🇿', country: 'New Zealand'),
      Currency(code: 'MXN', name: 'Mexican Peso', symbol: '\$', flag: '🇲🇽', country: 'Mexico'),
      Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷', country: 'Brazil'),
      Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦', country: 'South Africa'),
      Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽', flag: '🇷🇺', country: 'Russia'),
      Currency(code: 'TRY', name: 'Turkish Lira', symbol: '₺', flag: '🇹🇷', country: 'Turkey'),
      Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪', country: 'UAE'),
      Currency(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼', flag: '🇸🇦', country: 'Saudi Arabia'),
      Currency(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭', country: 'Thailand'),
      Currency(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp', flag: '🇮🇩', country: 'Indonesia'),
      Currency(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾', country: 'Malaysia'),
      Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭', country: 'Philippines'),
      Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: '₨', flag: '🇵🇰', country: 'Pakistan'),
      Currency(code: 'EGP', name: 'Egyptian Pound', symbol: '£', flag: '🇪🇬', country: 'Egypt'),
      Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬', country: 'Nigeria'),
      Currency(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', flag: '🇰🇪', country: 'Kenya'),
      Currency(code: 'CLP', name: 'Chilean Peso', symbol: '\$', flag: '🇨🇱', country: 'Chile'),
      Currency(code: 'COP', name: 'Colombian Peso', symbol: '\$', flag: '🇨🇴', country: 'Colombia'),
      Currency(code: 'ARS', name: 'Argentine Peso', symbol: '\$', flag: '🇦🇷', country: 'Argentina'),
      Currency(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč', flag: '🇨🇿', country: 'Czech Republic'),
      Currency(code: 'HUF', name: 'Hungarian Forint', symbol: 'Ft', flag: '🇭🇺', country: 'Hungary'),
      Currency(code: 'PLN', name: 'Polish Zloty', symbol: 'zł', flag: '🇵🇱', country: 'Poland'),
      Currency(code: 'ILS', name: 'Israeli Shekel', symbol: '₪', flag: '🇮🇱', country: 'Israel'),
      Currency(code: 'QAR', name: 'Qatari Riyal', symbol: '﷼', flag: '🇶🇦', country: 'Qatar'),
      Currency(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'KD', flag: '🇰🇼', country: 'Kuwait'),
      Currency(code: 'BHD', name: 'Bahraini Dinar', symbol: 'BD', flag: '🇧🇭', country: 'Bahrain'),
      Currency(code: 'OMR', name: 'Omani Rial', symbol: '﷼', flag: '🇴🇲', country: 'Oman'),
      Currency(code: 'JOD', name: 'Jordanian Dinar', symbol: 'JD', flag: '🇯🇴', country: 'Jordan'),
      Currency(code: 'LKR', name: 'Sri Lankan Rupee', symbol: '₨', flag: '🇱🇰', country: 'Sri Lanka'),
      Currency(code: 'BGN', name: 'Bulgarian Lev', symbol: 'лв', flag: '🇧🇬', country: 'Bulgaria'),
      Currency(code: 'UAH', name: 'Ukrainian Hryvnia', symbol: '₴', flag: '🇺🇦', country: 'Ukraine'),
      Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', flag: '🇬🇭', country: 'Ghana'),
      Currency(code: 'PEN', name: 'Peruvian Sol', symbol: 'S/', flag: '🇵🇪', country: 'Peru'),
      Currency(code: 'RON', name: 'Romanian Leu', symbol: 'lei', flag: '🇷🇴', country: 'Romania'),
    ];
  }
}
