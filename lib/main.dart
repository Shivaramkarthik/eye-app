import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user_model.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          seedColor: const Color(0xFF0284C7),
          primary: const Color(0xFF0284C7),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
