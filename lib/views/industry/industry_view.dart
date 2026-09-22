import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class IndustryView extends StatefulWidget {
  const IndustryView({super.key});

  @override
  State<IndustryView> createState() => _IndustryViewState();
}

class _IndustryViewState extends State<IndustryView> {
  final _db = SupabaseService.instance;
  String _selectedCategory = 'Pharma';

  final List<String> _categories = [
    'Retail',
    'Wholesale/distribution',
    'Pharma',
    'FMCG',
    'Manufacturing',
    'Restaurant',
  ];

  @override
  void initState() {
    super.initState();
    if (_db.activeCompany != null) {
      _selectedCategory = _db.activeCompany!.industryCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Industry-Specific Category Modules', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Configure the primary industry operating mode for your company:'),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;

                return Card(
                  color: isSelected ? const Color(0xFF0F52BA).withOpacity(0.15) : null,
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.category,
                      color: isSelected ? const Color(0xFF0F52BA) : Colors.grey,
                    ),
                    title: Text(cat, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('Operating mode for $cat business setup'),
                    trailing: isSelected ? const Chip(label: Text('ACTIVE MODE'), backgroundColor: Color(0xFF0F52BA)) : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Industry category set to: $cat')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
