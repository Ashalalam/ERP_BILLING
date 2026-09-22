import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Displays a UPI payment QR code for the given invoice total.
/// UPI deep-link format: upi://pay?pa=VPA&pn=Name&am=AMOUNT&cu=INR&tn=Note
Future<void> showUpiQrDialog(
  BuildContext context, {
  required double amount,
  required String invoiceNumber,
  String vpa = 'apexpharma@upi',
  String payeeName = 'Apex Pharma',
}) async {
  final upiString =
      'upi://pay?pa=$vpa&pn=${Uri.encodeComponent(payeeName)}'
      '&am=${amount.toStringAsFixed(2)}&cu=INR'
      '&tn=${Uri.encodeComponent('Invoice $invoiceNumber')}';

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.qr_code, color: Colors.orange),
          SizedBox(width: 8),
          Text('UPI Payment QR'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text('Invoice #$invoiceNumber',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          QrImageView(
            data: upiString,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Text('UPI ID: $vpa',
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Scan with any UPI app (GPay, PhonePe, Paytm, BHIM)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
