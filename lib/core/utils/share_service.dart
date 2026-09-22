import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';

/// Share Service — WhatsApp, Email and OS share sheet.
class ShareService {
  // ── WhatsApp ─────────────────────────────────────────────────────────────

  static String buildWhatsAppInvoiceUrl(Invoice invoice, String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final dateStr = DateFormat('dd-MM-yyyy').format(invoice.createdAt);
    final text = 'Hello! Your invoice #${invoice.invoiceNumber} dated $dateStr. '
        'Total: ₹${invoice.totalAmount.toStringAsFixed(2)}. Thank you!';
    return 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
  }

  static String buildWhatsAppRefillReminderUrl(
      String patientName, String drugName, String phone, DateTime refillDate) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final dateStr = DateFormat('dd-MM-yyyy').format(refillDate);
    final text = 'Dear $patientName, reminder: your $drugName refill is due on $dateStr. '
        'Contact your pharmacy to process your refill.';
    return 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
  }

  static Future<void> launchWhatsApp(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp not available. Link: $url')),
        );
      }
    }
  }

  // ── Email ─────────────────────────────────────────────────────────────────

  static String buildEmailInvoiceUrl(Invoice invoice, String email) {
    final subject = Uri.encodeComponent('Invoice #${invoice.invoiceNumber}');
    final body = Uri.encodeComponent(
        'Dear Customer,\n\nInvoice #${invoice.invoiceNumber}\nTotal: ₹${invoice.totalAmount.toStringAsFixed(2)}\n\nThank you!');
    return 'mailto:$email?subject=$subject&body=$body';
  }

  static Future<void> launchEmail(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client.')),
        );
      }
    }
  }

  // ── OS Share sheet ────────────────────────────────────────────────────────

  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  static Future<void> shareFile(String filePath, String filename) async {
    await Share.shareXFiles([XFile(filePath)], text: filename);
  }
}
