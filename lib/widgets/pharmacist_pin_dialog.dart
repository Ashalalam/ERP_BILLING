import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Shows a PIN entry dialog for pharmacist approval of controlled substances.
/// Returns true if PIN verified, false/null if dismissed.
Future<bool> showPharmacistPinDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _PharmacistPinDialog(),
  );
  return result ?? false;
}

class _PharmacistPinDialog extends StatefulWidget {
  const _PharmacistPinDialog();

  @override
  State<_PharmacistPinDialog> createState() => _PharmacistPinDialogState();
}

class _PharmacistPinDialogState extends State<_PharmacistPinDialog> {
  final _pinCtrl = TextEditingController();
  bool _wrong = false;
  bool _obscure = true;

  void _verify() {
    final ok = AuthService.instance.verifyPharmacistPin(_pinCtrl.text);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _wrong = true;
        _pinCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock, color: Colors.orange, size: 40),
      title: const Text('Pharmacist Authorization Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This invoice contains Schedule H, H1 or Narcotic substances.\n'
            'Enter pharmacist PIN to authorize dispensing.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinCtrl,
            obscureText: _obscure,
            maxLength: 6,
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: 'Enter PIN',
              errorText: _wrong ? 'Incorrect PIN. Try again.' : null,
              prefixIcon: const Icon(Icons.pin),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _verify,
          icon: const Icon(Icons.verified_user),
          label: const Text('Authorize'),
        ),
      ],
    );
  }
}
