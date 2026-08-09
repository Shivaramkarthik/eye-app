import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/app_theme.dart';
import 'models/user_model.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
  ));
  runApp(const SpeczApp());
}

class SpeczApp extends StatefulWidget {
  const SpeczApp({Key? key}) : super(key: key);

  @override
  State<SpeczApp> createState() => _SpeczAppState();
}

class _SpeczAppState extends State<SpeczApp> {
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    // Default logged in user for Karthik
    currentUser = UserModel(
      id: 'user_default',
      email: 'karthik@specz.co',
      name: 'Karthik',
      plan: 'free',
      status: 'free',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Specz.co - Digital Eye-Care Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
          secondary: AppTheme.primaryLight,
          surface: AppTheme.surface,
          error: AppTheme.error,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
        scaffoldBackgroundColor: AppTheme.scaffoldBg,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButton,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: AppTheme.outlineButton,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          color: AppTheme.cardWhite,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 20,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: StadiumBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: AppTheme.divider,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          backgroundColor: AppTheme.textPrimary,
        ),
      ),
      home: currentUser == null
          ? AuthScreen(
              onLoginSuccess: (user) => setState(() => currentUser = user),
            )
          : DashboardScreen(
              user: currentUser!,
              onLogout: () => setState(() => currentUser = null),
            ),
    );
  }
}
