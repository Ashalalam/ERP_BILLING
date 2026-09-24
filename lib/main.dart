import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'views/auth/login_view.dart';
import 'widgets/app_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env asset
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Initialise Supabase — falls back to demo mode on error
  if (supabaseUrl.isNotEmpty && !supabaseUrl.contains('YOUR_PROJECT')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase.initialize failed: $e. Running in demo/offline mode.');
    }
  } else {
    debugPrint('Supabase credentials not configured. Running in demo mode.');
  }

  // Load data (from Supabase or demo fallback)
  await SupabaseService.instance.initialize();

  runApp(const BillSproutApp());
}

class BillSproutApp extends StatelessWidget {
  const BillSproutApp({super.key});

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
