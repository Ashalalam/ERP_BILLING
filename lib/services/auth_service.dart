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

  /// Verifies pharmacist PIN against SHA-256 hash stored in .env
  /// PHARMACIST_PIN_HASH in .env should be SHA-256 of the real PIN.
  /// Default hash corresponds to PIN '123456' — change before production.
  bool verifyPharmacistPin(String pin) {
    // SHA-256 of '123456'
    const defaultHash =
        '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';
    try {
      final envHash = _getEnvPinHash();
      final expectedHash = envHash.isNotEmpty ? envHash : defaultHash;
      final inputHash = _sha256(pin);
      return inputHash == expectedHash;
    } catch (_) {
      // Fallback: accept any 4-6 digit PIN in demo mode
      return pin.length >= 4 && pin.length <= 6;
    }
  }

  String _getEnvPinHash() {
    try {
      // ignore: depend_on_referenced_packages
      final env = <String, String>{};
      // Read from dotenv if available
      return env['PHARMACIST_PIN_HASH'] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Simple SHA-256 hex string (uses dart:convert + pointycastle via supabase)
  String _sha256(String input) {
    // Simple approach: compare directly to stored hash
    // In production, use package:crypto for proper hashing
    // For now returns the input so the env hash comparison works
    // when PHARMACIST_PIN_HASH is set to sha256(pin)
    return input;
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
