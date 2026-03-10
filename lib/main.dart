import 'package:currency_converter/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/currency_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: const CurrencyConverterApp(),
    ),
  );
}

class CurrencyConverterApp extends StatelessWidget {
  const CurrencyConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        // Keep status bar icons in sync
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              theme.isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              theme.isDark ? ThemeProvider.darkBg : ThemeProvider.lightBg,
          systemNavigationBarIconBrightness:
              theme.isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'FXchange',
          debugShowCheckedModeBanner: false,
          themeMode: theme.themeMode,

          // ── Dark theme ──────────────────────────────────
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: ThemeProvider.darkBg,
            colorScheme: const ColorScheme.dark(
              primary: ThemeProvider.accent,
              secondary: ThemeProvider.accentBlue,
              surface: ThemeProvider.darkSurface,
              background: ThemeProvider.darkBg,
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),

          // ── Light theme ─────────────────────────────────
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: ThemeProvider.lightBg,
            colorScheme: const ColorScheme.light(
              primary: ThemeProvider.accent,
              secondary: ThemeProvider.accentBlue,
              surface: ThemeProvider.lightSurface,
              background: ThemeProvider.lightBg,
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, .6)));
    _scale = Tween<double>(begin: .7, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl, curve: const Interval(0, .6, curve: Curves.elasticOut)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ));
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? ThemeProvider.darkBg : ThemeProvider.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ThemeProvider.accent, ThemeProvider.accentBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: ThemeProvider.accent.withOpacity(.35),
                            blurRadius: 40,
                            spreadRadius: -5)
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/logo_Currensync.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('CurrenSync',
                      style: TextStyle(
                          color: isDark
                              ? ThemeProvider.darkTextPrim
                              : ThemeProvider.lightTextPrim,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Real-time currency converter',
                      style: TextStyle(
                          color: isDark
                              ? ThemeProvider.darkTextHint
                              : ThemeProvider.lightTextHint,
                          fontSize: 14)),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      backgroundColor: isDark
                          ? Colors.white10
                          : ThemeProvider.lightBorder,
                      valueColor: const AlwaysStoppedAnimation(
                          ThemeProvider.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

