import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'views/auth/login_view.dart';
import 'widgets/app_layout.dart';

// ── Supabase project credentials ──────────────────────────────────────────
// Replace these with your real Supabase project URL and anon key.
// Get them from: https://supabase.com/dashboard → Project Settings → API
const _supabaseUrl = 'https://cplwmlxacaxqbcsypyao.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwbHdtbHhhY2F4cWJjc3lweWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwNDIzNjMsImV4cCI6MjEwNTYxODM2M30.IuZHt1PhtacOTuGHX1F_p4Bg6E42KOMDpB1NsMwXXCc';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase — if credentials are placeholders, the app still
  // runs in demo mode because SupabaseService.initialize() catches errors.
  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase.initialize failed: $e. Running in demo/offline mode.');
  }

  // Load data (from Supabase or demo fallback)
  await SupabaseService.instance.initialize();

  runApp(const BillSproutApp());
}

class BillSproutApp extends StatefulWidget {
  const BillSproutApp({super.key});

  @override
  State<BillSproutApp> createState() => _BillSproutAppState();
}

class _BillSproutAppState extends State<BillSproutApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillSprout — Smart ERP & Billing by LIFESPROUT Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    if (auth.isAuthenticated) {
      return const AppLayout();
    }
    return LoginView(
      onLoginSuccess: () => setState(() {}),
    );
  }
}
