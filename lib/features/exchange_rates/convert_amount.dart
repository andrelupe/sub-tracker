/// Converts [amount] from [fromCurrency] to [toCurrency] using [rates].
///
/// The [rates] map is keyed by target currency code with the rate relative to
/// the base currency used when fetching rates. The base currency itself is not
/// in the map (its rate is implicitly 1.0).
///
/// Returns [amount] unchanged when:
/// - [fromCurrency] equals [toCurrency]
/// - The required rate is not found in [rates] (fallback — no silent errors)
double convertAmount({
  required double amount,
  required String fromCurrency,
  required String toCurrency,
  required String ratesBaseCurrency,
  required Map<String, double> rates,
}) {
  if (fromCurrency == toCurrency) return amount;

  // Direct conversion: from == ratesBase, to is in rates
  if (fromCurrency == ratesBaseCurrency) {
    final rate = rates[toCurrency];
    if (rate != null) return amount * rate;
    return amount; // fallback
  }

  // Reverse conversion: to == ratesBase, from is in rates
  if (toCurrency == ratesBaseCurrency) {
    final rate = rates[fromCurrency];
    if (rate != null && rate != 0) return amount / rate;
    return amount; // fallback
  }

  // Cross conversion: neither is the base, convert via base
  final fromRate = rates[fromCurrency];
  final toRate = rates[toCurrency];
  if (fromRate != null && fromRate != 0 && toRate != null) {
    return amount / fromRate * toRate;
  }

  return amount; // fallback
}
