import 'package:currency_converter/providers/theme_provider.dart';
import 'package:currency_converter/providers/ad_provider.dart';
import 'package:currency_converter/services/ad_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/currency_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  AdLogger.log('AdMob SDK initialized');
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
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
          title: 'CurrenSync',
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    
    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, .6)));
    _scale = Tween<double>(begin: .7, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl, curve: const Interval(0, .6, curve: Curves.elasticOut)));
    _ctrl.forward();
    
    // Show app open ad on first launch
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isFirstLaunch) {
        _isFirstLaunch = false;
        AdLogger.log('App launched - showing first app open ad');
        context.read<AdProvider>().showAppOpenAd();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Show app open ad when app resumes from background (after 3+ seconds)
    if (state == AppLifecycleState.resumed && !_isFirstLaunch) {
      AdLogger.log('App resumed - showing app open ad');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.read<AdProvider>().showAppOpenAd();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

                  /// Logo Container
                  Container(
                    width: 200,
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Image.asset(
                        'assets/images/icon_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// App Name
                  Text(
                    'CurrenSync',
                    style: GoogleFonts.orbitron(
                      color: isDark
                          ? ThemeProvider.darkTextPrim
                          : ThemeProvider.lightTextPrim,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Subtitle
                  Text(
                    'Real-time Currency Converter',
                    style: GoogleFonts.inter(
                      color: isDark
                          ? ThemeProvider.darkTextHint
                          : ThemeProvider.lightTextHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// Loading Indicator
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor:
                            isDark ? Colors.white10 : ThemeProvider.lightBorder,
                        valueColor: const AlwaysStoppedAnimation(
                          ThemeProvider.accent,
                        ),
                      ),
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

