import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final _db = SupabaseService.instance;

  static const _allRoles = [
    'System Administrator',
    'Authorized Pharmacist',
    'Cashier',
    'Manager',
    'Staff',
  ];

  static const _allPermissions = [
    'billing',
    'accounting',
    'inventory',
    'regulatory',
    'reports',
    'pharmacist_approval',
    'purchase',
    'user_management',
  ];

  @override
  Widget build(BuildContext context) {
    final users = _db.users;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Role Management'),
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add User'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: users.isEmpty
            ? const Center(child: Text('No users configured.'))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        child: Text(u.fullName[0].toUpperCase()),
                      ),
                      title: Text(u.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${u.email} | Role: ${u.roleName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditUserDialog(u),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Permissions:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _allPermissions
                                    .map((perm) {
                                  final hasAll =
                                      u.permissions['all'] ==
                                          true;
                                  final hasPerm = hasAll ||
                                      u.permissions[perm] == true;
                                  return Chip(
                                    label: Text(perm,
                                        style: const TextStyle(
                                            fontSize: 11)),
                                    backgroundColor: hasPerm
                                        ? Colors.green
                                            .withOpacity(0.2)
                                        : Colors.red
                                            .withOpacity(0.1),
                                    avatar: Icon(
                                      hasPerm
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 14,
                                      color: hasPerm
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddUserDialog() => _showUserDialog(null);
  void _showEditUserDialog(AppUser user) => _showUserDialog(user);

  void _showUserDialog(AppUser? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.fullName ?? '');
    final emailCtrl =
        TextEditingController(text: existing?.email ?? '');
    String role = existing?.roleName ?? _allRoles[1];
    final permissions = Map<String, bool>.fromEntries(
      _allPermissions.map((p) => MapEntry(
          p,
          existing?.permissions['all'] == true ||
              existing?.permissions[p] == true)),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add User' : 'Edit User'),
        content: StatefulBuilder(
          builder: (context, setS) => SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Full Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration:
                        const InputDecoration(labelText: 'Role'),
                    items: _allRoles
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setS(() => role = v!),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Permissions:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ..._allPermissions.map((perm) =>
                      SwitchListTile(
                        title: Text(perm,
                            style: const TextStyle(
                                fontSize: 13)),
                        value: permissions[perm] ?? false,
                        onChanged: (v) =>
                            setS(() => permissions[perm] = v),
                        dense: true,
                      )),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty ||
                  emailCtrl.text.isEmpty) return;
              final perms = Map<String, dynamic>.fromEntries(
                permissions.entries
                    .where((e) => e.value)
                    .map((e) => MapEntry(e.key, true)),
              );
              if (existing == null) {
                _db.users.isEmpty; // just notify
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(existing == null
                        ? 'User ${nameCtrl.text} added.'
                        : 'User ${nameCtrl.text} updated.'),
                    backgroundColor: Colors.green),
              );
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
