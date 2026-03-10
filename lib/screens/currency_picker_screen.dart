import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../models/currency.dart';

class CurrencyPickerScreen extends StatefulWidget {
  final String selectedCode;
  final String? excludeCode;
  final ThemeProvider theme;
  const CurrencyPickerScreen(
      {super.key,
      required this.selectedCode,
      this.excludeCode,
      required this.theme});

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  ThemeProvider get t => widget.theme;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = t.isDark;
    return Scaffold(
      backgroundColor: t.bg(isDark),
      appBar: AppBar(
        backgroundColor: t.bg(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: t.textSec(isDark), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Select Currency',
            style: GoogleFonts.inter(
                color: t.textPrim(isDark),
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: t.surface(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border(isDark)),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: t.textPrim(isDark)),
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search currency, country...',
                hintStyle:
                    TextStyle(color: t.textHint(isDark), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: t.textHint(isDark)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _q.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: t.textHint(isDark), size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _q = '');
                        })
                    : null,
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<CurrencyProvider>(
            builder: (context, provider, _) {
              List<Currency> currencies = provider.searchCurrencies(_q);
              if (widget.excludeCode != null) {
                currencies =
                    currencies.where((c) => c.code != widget.excludeCode).toList();
              }
              if (_q.isEmpty) {
                final favs =
                    currencies.where((c) => provider.isFavorite(c.code)).toList();
                final rest =
                    currencies.where((c) => !provider.isFavorite(c.code)).toList();
                currencies = [...favs, ...rest];
              }

              return ListView.builder(
                itemCount: currencies.length +
                    (_q.isEmpty && provider.favorites.isNotEmpty ? 2 : 0),
                itemBuilder: (context, index) {
                  if (_q.isEmpty) {
                    final favCount = currencies
                        .where((c) => provider.isFavorite(c.code))
                        .length;
                    if (index == 0) return _header('⭐  Favorites', isDark);
                    if (index == favCount + 1)
                      return _header('All Currencies', isDark);
                    final adj = index <= favCount ? index - 1 : index - 2;
                    return _tile(currencies[adj], provider, isDark);
                  }
                  return _tile(currencies[index], provider, isDark);
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _header(String title, bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(title,
            style: TextStyle(
                color: t.textHint(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .5)),
      );

  Widget _tile(Currency currency, CurrencyProvider provider, bool isDark) {
    final isSelected = currency.code == widget.selectedCode;
    final isFav = provider.isFavorite(currency.code);
    final rate = provider.rates[currency.code];

    return ListTile(
      onTap: () => Navigator.pop(context, currency.code),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: t.surface(isDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
            child: Text(currency.flag,
                style: const TextStyle(fontSize: 22))),
      ),
      title: Row(children: [
        Text(currency.code,
            style: GoogleFonts.spaceMono(
                color: isSelected
                    ? ThemeProvider.accent
                    : t.textPrim(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        if (isSelected) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ThemeProvider.accent.withOpacity(.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('selected',
                style: TextStyle(
                    color: ThemeProvider.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
      subtitle: Text(currency.name,
          style: TextStyle(color: t.textHint(isDark), fontSize: 12)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (rate != null)
          Text(rate.toStringAsFixed(rate >= 100 ? 2 : 4),
              style: GoogleFonts.spaceMono(
                  color: t.textHint(isDark), fontSize: 12)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => provider.toggleFavorite(currency.code),
          child: Icon(
              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFav ? ThemeProvider.gold : t.textHint(isDark),
              size: 20),
        ),
      ]),
    );
  }
}