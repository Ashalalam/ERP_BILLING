import 'package:flutter/material.dart';

class SplitPaymentResult {
  final String method;
  final double cashAmount;
  final double cardAmount;
  final double upiAmount;

  const SplitPaymentResult({
    required this.method,
    required this.cashAmount,
    required this.cardAmount,
    required this.upiAmount,
  });
}

/// Shows a payment dialog supporting single-tender and split-tender modes.
/// Returns a [SplitPaymentResult] or null if dismissed.
Future<SplitPaymentResult?> showPaymentDialog(
  BuildContext context, {
  required double totalAmount,
}) async {
  return showDialog<SplitPaymentResult>(
    context: context,
    builder: (ctx) => _PaymentDialog(totalAmount: totalAmount),
  );
}

class _PaymentDialog extends StatefulWidget {
  final double totalAmount;
  const _PaymentDialog({required this.totalAmount});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _method = 'cash';
  final _cashCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  double get _cashAmt => double.tryParse(_cashCtrl.text) ?? 0;
  double get _cardAmt => double.tryParse(_cardCtrl.text) ?? 0;
  double get _upiAmt => double.tryParse(_upiCtrl.text) ?? 0;
  double get _tendered => _cashAmt + _cardAmt + _upiAmt;
  double get _balance => widget.totalAmount - _tendered;

  @override
  void initState() {
    super.initState();
    _cashCtrl.text = widget.totalAmount.toStringAsFixed(2);
  }

  void _onMethodChanged(String m) {
    setState(() {
      _method = m;
      _cashCtrl.text = '';
      _cardCtrl.text = '';
      _upiCtrl.text = '';
      if (m == 'cash') _cashCtrl.text = widget.totalAmount.toStringAsFixed(2);
      if (m == 'card') _cardCtrl.text = widget.totalAmount.toStringAsFixed(2);
      if (m == 'upi') _upiCtrl.text = widget.totalAmount.toStringAsFixed(2);
    });
  }

  void _confirm() {
    if (_method != 'split' && _balance.abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount mismatch. Balance: ₹${_balance.toStringAsFixed(2)}')),
      );
      return;
    }
    if (_method == 'split' && _balance.abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Split amounts must sum to ₹${widget.totalAmount.toStringAsFixed(2)}. '
            'Remaining: ₹${_balance.toStringAsFixed(2)}')),
      );
      return;
    }
    Navigator.pop(
      context,
      SplitPaymentResult(
        method: _method,
        cashAmount: _cashAmt,
        cardAmount: _cardAmt,
        upiAmount: _upiAmt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.payment, color: Colors.green),
          const SizedBox(width: 8),
          Text('Payment — ₹${widget.totalAmount.toStringAsFixed(2)}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Method selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.money)),
                ButtonSegment(value: 'card', label: Text('Card'), icon: Icon(Icons.credit_card)),
                ButtonSegment(value: 'upi', label: Text('UPI'), icon: Icon(Icons.qr_code)),
                ButtonSegment(value: 'split', label: Text('Split'), icon: Icon(Icons.call_split)),
              ],
              selected: {_method},
              onSelectionChanged: (s) => _onMethodChanged(s.first),
            ),
            const SizedBox(height: 20),
            if (_method == 'cash' || _method == 'split')
              _amountField(_cashCtrl, 'Cash Amount', Icons.money, Colors.green),
            if (_method == 'card' || _method == 'split')
              _amountField(_cardCtrl, 'Card Amount', Icons.credit_card, Colors.blue),
            if (_method == 'upi' || _method == 'split')
              _amountField(_upiCtrl, 'UPI Amount', Icons.qr_code, Colors.orange),
            if (_method == 'split') ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total tendered:'),
                  Text('₹${_tendered.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance remaining:'),
                  Text(
                    '₹${_balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _balance.abs() < 0.01 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (_method == 'cash') ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change to return:'),
                  Text(
                    '₹${(-_balance).clamp(0, double.infinity).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirm Payment'),
        ),
      ],
    );
  }

  Widget _amountField(TextEditingController ctrl, String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color),
        ),
      ),
    );
  }
}
