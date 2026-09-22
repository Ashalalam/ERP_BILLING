import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef DateRangeCallback = void Function(DateTime? from, DateTime? to);

/// A reusable date range filter bar used across reports, accounting, and GST views.
class DateRangeFilterBar extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateRangeCallback onChanged;

  const DateRangeFilterBar({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onChanged,
  });

  static final _fmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Period:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          _DateButton(
            label: fromDate != null ? _fmt.format(fromDate!) : 'From Date',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) onChanged(picked, toDate);
            },
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('→')),
          _DateButton(
            label: toDate != null ? _fmt.format(toDate!) : 'To Date',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: toDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) onChanged(fromDate, picked);
            },
          ),
          const SizedBox(width: 12),
          // Quick presets
          _PresetChip(label: 'This Month', onTap: () {
            final now = DateTime.now();
            onChanged(DateTime(now.year, now.month, 1), now);
          }),
          const SizedBox(width: 6),
          _PresetChip(label: 'Last Month', onTap: () {
            final now = DateTime.now();
            final first = DateTime(now.year, now.month - 1, 1);
            final last = DateTime(now.year, now.month, 0);
            onChanged(first, last);
          }),
          const SizedBox(width: 6),
          _PresetChip(label: 'This FY', onTap: () {
            final now = DateTime.now();
            final fyStart = now.month >= 4
                ? DateTime(now.year, 4, 1)
                : DateTime(now.year - 1, 4, 1);
            onChanged(fyStart, now);
          }),
          const SizedBox(width: 6),
          _PresetChip(label: 'All Time', onTap: () => onChanged(null, null)),
          if (fromDate != null || toDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Clear filter',
              onPressed: () => onChanged(null, null),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_today, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
