import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../models/currency.dart';
import 'currency_picker_screen.dart';
import 'all_rates_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _amountCtrl = TextEditingController(text: '1');
  final _amountFocus = FocusNode();
  late AnimationController _swapCtrl;
  late Animation<double> _swapAnim;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _swapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _swapAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _swapCtrl, curve: Curves.elasticOut));

    _amountCtrl.addListener(() {
      final val = double.tryParse(_amountCtrl.text);
      if (val != null) {
        context.read<CurrencyProvider>().setAmount(val);
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    _swapCtrl.dispose();
    super.dispose();
  }

  void _onSwap() {
    final p = context.read<CurrencyProvider>();
    p.addToHistory(p.baseCurrency, p.targetCurrency, p.amount, p.convertedAmount);
    _swapCtrl.forward(from: 0);
    p.swapCurrencies();
    HapticFeedback.mediumImpact();
  }

  void _setQuickAmount(int amount) {
    _amountCtrl.text = amount.toString();
    context.read<CurrencyProvider>().setAmount(amount.toDouble());
    _amountFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.bg(isDark),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, isDark),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _buildConverterTab(theme, isDark),
                    AllRatesScreen(theme: theme),
                    HistoryScreen(theme: theme),
                  ],
                ),
              ),
              _buildBottomNav(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeProvider theme, bool isDark) {
    return Consumer<CurrencyProvider>(
      builder: (context, provider, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: theme.bg(isDark),
          border: Border(bottom: BorderSide(color: theme.border(isDark))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CurrenSync',
                  style: GoogleFonts.orbitron(
                      color: theme.textPrim(isDark),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              if (provider.lastUpdated != null)
                Text(' Last Updated:\n ${DateFormat('dd/MM/yyyy • HH:mm').format(provider.lastUpdated!)}',
                    style: TextStyle(color: theme.textPrim(isDark), fontSize: 12)),
            ]),
            Row(children: [
              _IconBtn(
                icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFFFC107) : const Color(0xFF5C6BC0),
                bg: theme.surface(isDark),
                border: theme.border(isDark),
                onTap: () => context.read<ThemeProvider>().toggleTheme(),
              ),
              const SizedBox(width: 8),
              if (provider.isLoading)
                SizedBox(
                    width: 40, height: 40,
                    child: Center(
                        child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: ThemeProvider.accent))))
              else
                _IconBtn(
                  icon: Icons.refresh_rounded,
                  color: theme.textSec(isDark),
                  bg: theme.surface(isDark),
                  border: theme.border(isDark),
                  onTap: provider.fetchRates,
                ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Converter tab ────────────────────────────────────────────────────────
  Widget _buildConverterTab(ThemeProvider theme, bool isDark) {
    return Consumer<CurrencyProvider>(
      builder: (context, provider, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(children: [
          _buildAmountInputCard(provider, theme, isDark),
          const SizedBox(height: 16),
          _buildConverterCard(provider, theme, isDark),
          const SizedBox(height: 16),
          _buildRateInfo(provider, theme, isDark),
          const SizedBox(height: 16),
          _buildFavoritesSection(provider, theme, isDark),
        ]),
      ),
    );
  }

  // ── Main converter card (from/to) ────────────────────────────────────────
  Widget _buildConverterCard(
      CurrencyProvider provider, ThemeProvider theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border(isDark)),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? ThemeProvider.accent.withOpacity(.05)
                  : Colors.black.withOpacity(.06),
              blurRadius: 24,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        // FROM row
        _buildCurrencyRow(provider, theme, isDark,
            isBase: true,
            code: provider.baseCurrency,
            amount: provider.amount),
        _buildSwapDivider(theme, isDark),
        // TO row
        _buildCurrencyRow(provider, theme, isDark,
            isBase: false,
            code: provider.targetCurrency,
            amount: provider.convertedAmount),
        // Save button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: GestureDetector(
            onTap: () {
              provider.addToHistory(provider.baseCurrency,
                  provider.targetCurrency, provider.amount, provider.convertedAmount);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Row(children: [
                  Icon(Icons.check_circle_rounded,
                      color: ThemeProvider.accent, size: 16),
                  const SizedBox(width: 8),
                  Text('Saved to history',
                  style: TextStyle(color: theme.textPrim(isDark)),),
                ]),
                backgroundColor: theme.surface(isDark),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 1),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: ThemeProvider.accent.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ThemeProvider.accent.withOpacity(.3)),
              ),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bookmark_add_rounded,
                      color: ThemeProvider.accent, size: 15),
                  const SizedBox(width: 6),
                  Text('Save Conversion',
                      style: TextStyle(
                          color: ThemeProvider.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCurrencyRow(
      CurrencyProvider provider, ThemeProvider theme, bool isDark,
      {required bool isBase, required String code, required double amount}) {
    final currency = provider.getCurrency(code);
    return GestureDetector(
      onTap: () async {
        _amountFocus.unfocus();
        final selected = await Navigator.push<String>(context,
            MaterialPageRoute(
                builder: (_) => CurrencyPickerScreen(
                    selectedCode: code,
                    excludeCode: isBase
                        ? provider.targetCurrency
                        : provider.baseCurrency,
                    theme: theme)));
        if (selected != null) {
          if (isBase) provider.setBaseCurrency(selected);
          else provider.setTargetCurrency(selected);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Row(children: [
          // Flag pill
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: theme.card(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border(isDark)),
            ),
            child: Center(
                child: Text(currency?.flag ?? '🏳️',
                    style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          // Currency info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(code,
                    style: GoogleFonts.spaceMono(
                        color: theme.textPrim(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: ThemeProvider.accent, size: 18),
              ]),
              Text(currency?.name ?? '',
                  style: TextStyle(color: theme.textHint(isDark), fontSize: 11)),
            ]),
          ),
          // Amount display
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_fmt(amount),
                style: GoogleFonts.spaceMono(
                    color: isBase ? ThemeProvider.accent : theme.textPrim(isDark),
                    fontSize: isBase ? 24 : 20,
                    fontWeight: FontWeight.w700)),
            Text(currency?.symbol ?? '',
                style: TextStyle(color: theme.textHint(isDark), fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSwapDivider(ThemeProvider theme, bool isDark) {
    return Stack(alignment: Alignment.center, children: [
      Container(height: 1, color: theme.border(isDark)),
      AnimatedBuilder(
        animation: _swapAnim,
        builder: (_, child) =>
            Transform.rotate(angle: _swapAnim.value * 3.14159, child: child),
        child: GestureDetector(
          onTap: _onSwap,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [ThemeProvider.accent, ThemeProvider.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: ThemeProvider.accent.withOpacity(.3),
                    blurRadius: 12)
              ],
            ),
            child: const Icon(Icons.swap_vert_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ),
    ]);
  }

  // ── Amount input card (replaces numpad) ──────────────────────────────────
  Widget _buildAmountInputCard(
      CurrencyProvider provider, ThemeProvider theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border(isDark)),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(.2)
                  : Colors.black.withOpacity(.04),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Label
        Row(children: [
          Icon(Icons.edit_rounded, color: ThemeProvider.accent, size: 14),
          const SizedBox(width: 6),
          Text('Enter Amount',
              style: TextStyle(
                  color: theme.textPrim(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: .3)),
        ]),
        const SizedBox(height: 10),

        // Text field
        Container(
          decoration: BoxDecoration(
            color: theme.card(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _amountFocus.hasFocus
                  ? ThemeProvider.accent
                  : theme.border(isDark),
              width: _amountFocus.hasFocus ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            // Currency symbol badge
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeProvider.accent.withOpacity(.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.getCurrency(provider.baseCurrency)?.symbol ?? '\$',
                style: TextStyle(
                    color: ThemeProvider.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            // Input
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                focusNode: _amountFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: GoogleFonts.spaceMono(
                    color: theme.textPrim(isDark),
                    fontSize: 22,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.spaceMono(
                      color: theme.textHint(isDark), fontSize: 22),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) provider.setAmount(parsed);
                },
                onTap: () {
                  // Select all text when tapped for easy replace
                  _amountCtrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _amountCtrl.text.length);
                  setState(() {});
                },
              ),
            ),
            // Clear button
            if (_amountCtrl.text.isNotEmpty && _amountCtrl.text != '0')
              GestureDetector(
                onTap: () {
                  _amountCtrl.text = '0';
                  provider.setAmount(0);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.cancel_rounded,
                      color: theme.textHint(isDark), size: 20),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),

        // Quick amount chips
        Row(children: [
          Text('Quick:',
              style: TextStyle(
                  color: theme.textHint(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 10, 100, 500, 1000, 5000, 10000]
                    .map((a) => _quickChip(a, provider, theme, isDark))
                    .toList(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Common presets row
        Row(children: [
          Text('Presets:',
              style: TextStyle(
                  color: theme.textHint(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['25', '50', '75', '250', '2500']
                    .map((a) => _presetChip(a, provider, theme, isDark))
                    .toList(),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _quickChip(int amount, CurrencyProvider provider,
      ThemeProvider theme, bool isDark) {
    final isSelected = provider.amount == amount.toDouble();
    final label = amount >= 1000 ? '${amount ~/ 1000}K' : '$amount';
    return GestureDetector(
      onTap: () => _setQuickAmount(amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ThemeProvider.accent : theme.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? ThemeProvider.accent : theme.border(isDark)),
        ),
        child: Text(label,
            style: GoogleFonts.spaceMono(
                color: isSelected ? Colors.white : theme.textSec(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _presetChip(String amount, CurrencyProvider provider,
      ThemeProvider theme, bool isDark) {
    final val = double.parse(amount);
    final isSelected = provider.amount == val;
    return GestureDetector(
      onTap: () {
        _amountCtrl.text = amount;
        provider.setAmount(val);
        _amountFocus.unfocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeProvider.accentBlue.withOpacity(.15)
              : theme.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? ThemeProvider.accentBlue
                  : theme.border(isDark)),
        ),
        child: Text(amount,
            style: GoogleFonts.spaceMono(
                color: isSelected
                    ? ThemeProvider.accentBlue
                    : theme.textSec(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Rate info ─────────────────────────────────────────────────────────────
  Widget _buildRateInfo(
      CurrencyProvider provider, ThemeProvider theme, bool isDark) {
    if (provider.rates.isEmpty) return const SizedBox();
    final rate = provider.exchangeRate;
    final inverse = rate > 0 ? 1 / rate : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border(isDark)),
      ),
      child: Column(children: [
        // Exchange rate headline
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('1 ${provider.baseCurrency}  =  ',
              style: TextStyle(color: theme.textHint(isDark), fontSize: 13)),
          Text(_fmtRate(rate),
              style: GoogleFonts.spaceMono(
                  color: ThemeProvider.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text('  ${provider.targetCurrency}',
              style: TextStyle(color: theme.textHint(isDark), fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Divider(color: theme.border(isDark), height: 1),
        const SizedBox(height: 10),
        // Stats row
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _rateStat('Rate', _fmtRate(rate), theme, isDark),
          _vDivider(theme, isDark),
          _rateStat('Inverse', _fmtRate(inverse.toDouble()), theme, isDark),
          _vDivider(theme, isDark),
          _rateStat('24h Change', '+0.12%', theme, isDark,
              color: ThemeProvider.accent),
        ]),
      ]),
    );
  }

  Widget _vDivider(ThemeProvider theme, bool isDark) =>
      Container(width: 1, height: 32, color: theme.border(isDark));

  Widget _rateStat(String label, String value, ThemeProvider theme, bool isDark,
      {Color? color}) {
    return Column(children: [
      Text(label,
          style: TextStyle(color: theme.textHint(isDark), fontSize: 10)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.spaceMono(
              color: color ?? theme.textPrim(isDark),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Favourites ────────────────────────────────────────────────────────────
  Widget _buildFavoritesSection(
      CurrencyProvider provider, ThemeProvider theme, bool isDark) {
    if (provider.favoriteCurrencies.isEmpty) return const SizedBox();
    final baseRate = provider.rates[provider.baseCurrency] ?? 1.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.star_rounded, color: ThemeProvider.gold, size: 14),
          const SizedBox(width: 5),
          Text('Quick Convert',
              style: TextStyle(
                  color: theme.textHint(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
        GestureDetector(
          onTap: () => setState(() => _tab = 1),
          child: Text('See All ›',
              style: TextStyle(color: ThemeProvider.accent, fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 10),
      ...provider.favoriteCurrencies.take(5).map((c) {
        final targetRate = provider.rates[c.code] ?? 1.0;
        final converted = (provider.amount / baseRate) * targetRate;
        return _buildFavRow(provider, c, converted, theme, isDark);
      }),
    ]);
  }

  Widget _buildFavRow(CurrencyProvider provider, Currency currency,
      double converted, ThemeProvider theme, bool isDark) {
    final isTarget = provider.targetCurrency == currency.code;
    return GestureDetector(
      onTap: () {
        provider.setTargetCurrency(currency.code);
        setState(() => _tab = 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isTarget
              ? ThemeProvider.accent.withOpacity(.07)
              : theme.card(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isTarget ? ThemeProvider.accent.withOpacity(.4) : theme.border(isDark)),
        ),
        child: Row(children: [
          Text(currency.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(currency.code,
                  style: GoogleFonts.spaceMono(
                      color: isTarget ? ThemeProvider.accent : theme.textPrim(isDark),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(currency.country,
                  style: TextStyle(color: theme.textHint(isDark), fontSize: 11)),
            ]),
          ),
          Text(_fmt(converted),
              style: GoogleFonts.spaceMono(
                  color: theme.textPrim(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(currency.symbol,
              style: TextStyle(color: theme.textHint(isDark), fontSize: 12)),
        ]),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav(ThemeProvider theme, bool isDark) {
    const items = [
      {'icon': Icons.currency_exchange_rounded, 'label': 'Convert'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Rates'},
      {'icon': Icons.history_rounded, 'label': 'History'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.bg(isDark),
        border: Border(top: BorderSide(color: theme.border(isDark))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return GestureDetector(
            onTap: () {
              _amountFocus.unfocus();
              setState(() => _tab = e.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? ThemeProvider.accent.withOpacity(.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value['icon'] as IconData,
                    color: sel ? ThemeProvider.accent : theme.textHint(isDark),
                    size: 22),
                const SizedBox(height: 3),
                Text(e.value['label'] as String,
                    style: TextStyle(
                        color: sel ? ThemeProvider.accent : theme.textHint(isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(double v) {
    if (v == 0) return '0';
    if (v >= 1000000) return NumberFormat('#,##0.00').format(v);
    if (v >= 1) return NumberFormat('#,##0.####').format(v);
    return NumberFormat('0.######').format(v);
  }

  String _fmtRate(double v) {
    if (v >= 1000) return NumberFormat('#,##0.00').format(v);
    if (v >= 1) return NumberFormat('0.####').format(v);
    return NumberFormat('0.######').format(v);
  }
}

// ── Small icon button ─────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg, border;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.border,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}