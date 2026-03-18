import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../models/currency.dart';

class AllRatesScreen extends StatefulWidget {
  final ThemeProvider theme;
  final VoidCallback? onScreenOpen;
  
  const AllRatesScreen({
    super.key,
    required this.theme,
    this.onScreenOpen,
  });

  @override
  State<AllRatesScreen> createState() => _AllRatesScreenState();
}

class _AllRatesScreenState extends State<AllRatesScreen> {
  String _q = '';
  String _sort = 'name';
  bool _hasNotifiedOpen = false;

  ThemeProvider get t => widget.theme;

  @override
  void initState() {
    super.initState();
    // Notify parent screen that this screen was opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasNotifiedOpen && widget.onScreenOpen != null) {
        _hasNotifiedOpen = true;
        widget.onScreenOpen!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = t.isDark;
    return Consumer<CurrencyProvider>(
      builder: (context, provider, _) {
        List<Currency> currencies = provider.searchCurrencies(_q);
        if (_sort == 'name') {
          currencies.sort((a, b) => a.code.compareTo(b.code));
        } else if (_sort == 'rate_asc') {
          currencies.sort((a, b) =>
              (provider.rates[a.code] ?? 0).compareTo(provider.rates[b.code] ?? 0));
        } else {
          currencies.sort((a, b) =>
              (provider.rates[b.code] ?? 0).compareTo(provider.rates[a.code] ?? 0));
        }

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: t.surface(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.border(isDark)),
                ),
                child: TextField(
                  style: TextStyle(color: t.textPrim(isDark), fontSize: 14),
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Search currencies...',
                    hintStyle:
                        TextStyle(color: t.textHint(isDark), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: t.textHint(isDark), size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Sort / base row
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: t.surface(isDark),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.border(isDark)),
                    ),
                    child: Row(children: [
                      Text(provider.getCurrency(provider.baseCurrency)?.flag ?? '',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('Base: ${provider.baseCurrency}',
                          style: TextStyle(
                              color: t.textSec(isDark), fontSize: 12)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  color: t.surface(isDark),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => [
                    _item('name', 'Sort A→Z', isDark),
                    _item('rate_asc', 'Rate Low→High', isDark),
                    _item('rate_desc', 'Rate High→Low', isDark),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: t.surface(isDark),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.border(isDark)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.sort_rounded,
                          color: ThemeProvider.accent, size: 16),
                      const SizedBox(width: 4),
                      Text('Sort',
                          style: TextStyle(
                              color: t.textSec(isDark), fontSize: 12)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: currencies.length,
              itemBuilder: (context, i) =>
                  _rateCard(currencies[i], provider, isDark),
            ),
          ),
        ]);
      },
    );
  }

  PopupMenuItem<String> _item(String value, String label, bool isDark) =>
      PopupMenuItem(
        value: value,
        child: Text(label,
            style: TextStyle(
                color: _sort == value
                    ? ThemeProvider.accent
                    : t.textSec(isDark),
                fontSize: 13)),
      );

  Widget _rateCard(
      Currency currency, CurrencyProvider provider, bool isDark) {
    final baseRate = provider.rates[provider.baseCurrency] ?? 1.0;
    final targetRate = provider.rates[currency.code] ?? 1.0;
    final converted = (1.0 / baseRate) * targetRate;
    final isFav = provider.isFavorite(currency.code);
    final change = (currency.code.hashCode % 200 - 100) / 1000.0;
    final pos = change >= 0;

    return GestureDetector(
      onTap: () {
        provider.setTargetCurrency(currency.code);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${currency.code} set as target',
          style: TextStyle(color: t.textPrim(isDark),),),
          backgroundColor: t.surface(isDark),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: t.card(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border(isDark)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: t.surface(isDark),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(currency.flag,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(currency.code,
                  style: GoogleFonts.spaceMono(
                      color: t.textPrim(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(currency.name,
                  style:
                      TextStyle(color: t.textHint(isDark), fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_fmtRate(converted),
                style: GoogleFonts.spaceMono(
                    color: t.textPrim(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  pos ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: pos ? ThemeProvider.accent : ThemeProvider.danger,
                  size: 16),
              Text('${(change.abs() * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: pos
                          ? ThemeProvider.accent
                          : ThemeProvider.danger,
                      fontSize: 10)),
            ]),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.toggleFavorite(currency.code),
            child: Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFav ? ThemeProvider.gold : t.textHint(isDark),
              size: 20,
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtRate(double r) {
    if (r >= 1000) return NumberFormat('#,##0.00').format(r);
    if (r >= 1) return NumberFormat('0.####').format(r);
    return NumberFormat('0.######').format(r);
  }
}