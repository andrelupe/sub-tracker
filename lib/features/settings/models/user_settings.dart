/// User settings from the API.
///
/// Currently holds only the base currency preference.
class UserSettings {
  const UserSettings({
    required this.baseCurrency,
    required this.updatedAt,
  });

  final String baseCurrency;
  final DateTime updatedAt;

  /// Supported currencies for the base currency setting.
  static const List<String> supportedCurrencies = ['EUR', 'USD', 'GBP'];

  /// Returns the currency symbol for a given currency code.
  static String currencySymbol(String currency) {
    return switch (currency.toUpperCase()) {
      'EUR' => '\u20AC',
      'USD' => '\$',
      'GBP' => '\u00A3',
      _ => currency,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      baseCurrency: json['baseCurrency'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
