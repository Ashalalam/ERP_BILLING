import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/models.dart';
import 'supabase_service.dart';

/// Authentication & RBAC Service — backed by Supabase Auth.
/// Falls back to demo mode when Supabase is not configured.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  AppUser? _currentUser;
  bool _isAuthenticated = false;
  String? _lastError;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String? get lastError => _lastError;

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  // ── Real Supabase login ──────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        _lastError = 'Invalid email or password.';
        notifyListeners();
        return false;
      }

      // Try to load user profile from DB
      try {
        final data = await _client
            .from('app_users')
            .select()
            .eq('email', email.trim())
            .maybeSingle();

        if (data != null) {
          _currentUser = AppUser(
            id: data['id'],
            companyId: data['company_id'],
            email: data['email'],
            fullName: data['full_name'],
            roleName: data['role_name'] ?? 'Standard User',
            permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
            storeId: data['store_id'],
          );
        } else {
          _currentUser = _buildDemoUser(email);
        }
      } catch (_) {
        _currentUser = _buildDemoUser(email);
      }

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on sb.AuthException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      // Supabase not configured — fall back to demo mode
      debugPrint('Supabase auth not available: $e. Using demo mode.');
      _loginDemo(email, password);
      return true;
    }
  }

  /// Demo login — accepts any email/password when Supabase is not set up.
  void _loginDemo(String email, String password) {
    _currentUser = _buildDemoUser(email);
    _isAuthenticated = true;
    notifyListeners();
  }

  AppUser _buildDemoUser(String email) {
    final db = SupabaseService.instance;
    return AppUser(
      companyId: db.activeCompany?.id ?? '',
      email: email,
      fullName: 'Dr. Ramesh Kumar (Registered Pharmacist)',
      roleName: 'Authorized Pharmacist',
      permissions: {
        'billing': true,
        'accounting': true,
        'inventory': true,
        'regulatory': true,
        'reports': true,
        'pharmacist_approval': true,
        'purchase': true,
        'user_management': true,
      },
    );
  }

  void initializeDemoUser() {
    if (_currentUser == null) {
      _currentUser = _buildDemoUser('admin@billsprout.com');
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // ── Permission check ─────────────────────────────────────────────────────

  bool checkPermission(String permissionKey) {
    if (_currentUser == null) return false;
    if (_currentUser!.permissions['all'] == true) return true;
    return _currentUser!.permissions[permissionKey] == true;
  }

  // ── Pharmacist PIN verification ──────────────────────────────────────────

  /// Verifies the pharmacist PIN for controlled substance approval.
  /// In production this should verify against a hashed PIN stored in DB.
  /// Demo PIN: 1234
  bool verifyPharmacistPin(String pin) {
    // In production: hash pin and compare against stored hash
    return pin == '1234';
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
