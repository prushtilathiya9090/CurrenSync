import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';

class HistoryScreen extends StatelessWidget {
  final ThemeProvider theme;
  const HistoryScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.isDark;
    return Consumer<CurrencyProvider>(
      builder: (context, provider, _) {
        final history = provider.conversionHistory;

        if (history.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history_rounded,
                  color: theme.textHint(isDark).withOpacity(.3), size: 64),
              const SizedBox(height: 16),
              Text('No conversion history yet',
                  style: TextStyle(color: theme.textHint(isDark), fontSize: 16)),
              const SizedBox(height: 6),
              Text('Tap "Save Conversion" to record one',
                  style: TextStyle(
                      color: theme.textHint(isDark).withOpacity(.6),
                      fontSize: 13)),
            ]),
          );
        }

        return Column(children: [
          // ── Header bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${history.length} saved',
                    style: TextStyle(
                        color: theme.textHint(isDark), fontSize: 13)),
                GestureDetector(
                  onTap: () => _confirmClearAll(context, provider, isDark),
                  child: Text('Clear all',
                      style: TextStyle(
                          color: ThemeProvider.danger, fontSize: 13)),
                ),
              ],
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final from = provider.getCurrency(item['from']);
                final to   = provider.getCurrency(item['to']);
                final time = item['timestamp'] as DateTime;

                // Swipe-to-delete wrapping each card
                return Dismissible(
                  key: ValueKey('${item['from']}_${item['to']}_${time.millisecondsSinceEpoch}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    provider.removeHistoryAt(index);
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Record deleted'),
                      backgroundColor: theme.surface(isDark),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: ThemeProvider.accent,
                        onPressed: () => provider.undoDelete(),
                      ),
                    ));
                  },
                  // Red delete background revealed on swipe
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: ThemeProvider.danger.withOpacity(.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(height: 4),
                        Text('Delete',
                            style: TextStyle(
                                color: Colors.white.withOpacity(.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  child: _HistoryCard(
                    item: item,
                    from: from,
                    to: to,
                    time: time,
                    theme: theme,
                    isDark: isDark,
                    onDelete: () => _confirmDelete(context, provider, index, isDark),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  // ── Confirm single delete dialog ─────────────────────────────────────────
  void _confirmDelete(BuildContext context, CurrencyProvider provider,
      int index, bool isDark) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Record',
            style: TextStyle(
                color: theme.textPrim(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text('Remove this conversion from history?',
            style: TextStyle(color: theme.textSec(isDark), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: theme.textHint(isDark))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeHistoryAt(index);
              HapticFeedback.mediumImpact();
            },
            child: Text('Delete',
                style: TextStyle(
                    color: ThemeProvider.danger,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Confirm clear all dialog ─────────────────────────────────────────────
  void _confirmClearAll(BuildContext context, CurrencyProvider provider,
      bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Clear All History',
            style: TextStyle(
                color: theme.textPrim(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently delete all ${provider.conversionHistory.length} records.',
            style: TextStyle(color: theme.textSec(isDark), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: theme.textHint(isDark))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.clearHistory();
              HapticFeedback.mediumImpact();
            },
            child: Text('Clear All',
                style: TextStyle(
                    color: ThemeProvider.danger,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── History card widget ───────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final dynamic from, to;
  final DateTime time;
  final ThemeProvider theme;
  final bool isDark;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.from,
    required this.to,
    required this.time,
    required this.theme,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(15, 13, 10, 13),
      decoration: BoxDecoration(
        color: theme.card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border(isDark)),
      ),
      child: Row(children: [
        // ── Left: conversion info ──────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Currency pair
              Row(children: [
                Text(from?.flag ?? '', style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text('${item['from']}',
                    style: GoogleFonts.spaceMono(
                        color: theme.textPrim(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: ThemeProvider.accent, size: 13),
                ),
                Text(to?.flag ?? '', style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text('${item['to']}',
                    style: GoogleFonts.spaceMono(
                        color: theme.textPrim(isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 5),
              // Amounts
              Text('${_f(item['amount'])}  →  ${_f(item['result'])}',
                  style: TextStyle(
                      color: theme.textSec(isDark), fontSize: 12)),
              const SizedBox(height: 2),
              // Rate
              Text('Rate: ${(item['rate'] as double).toStringAsFixed(6)}',
                  style: TextStyle(
                      color: theme.textHint(isDark), fontSize: 10)),
            ],
          ),
        ),

        // ── Right: time + delete button ────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat('HH:mm').format(time),
                style: TextStyle(
                    color: theme.textSec(isDark), fontSize: 12)),
            Text(DateFormat('dd MMM').format(time),
                style: TextStyle(
                    color: theme.textHint(isDark), fontSize: 10)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: ThemeProvider.danger.withOpacity(.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: ThemeProvider.danger.withOpacity(.25)),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: ThemeProvider.danger, size: 15),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  String _f(dynamic v) {
    final d = (v as num).toDouble();
    if (d >= 1000) return NumberFormat('#,##0.##').format(d);
    return NumberFormat('0.####').format(d);
  }
}