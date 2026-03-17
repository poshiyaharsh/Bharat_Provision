import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current logged-in user role: 'superadmin' | 'admin' | 'employee'
/// Defaults to 'admin'. Updated during a login flow.
final currentRoleProvider = StateProvider<String>((ref) => 'admin');

/// Returns true if the given role may access the Udhaar module.
bool canAccessUdhaar(String role) =>
    role == 'superadmin' || role == 'admin';
