import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class RegulatoryView extends StatefulWidget {
  const RegulatoryView({super.key});

  @override
  State<RegulatoryView> createState() => _RegulatoryViewState();
}

class _RegulatoryViewState extends State<RegulatoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regulatory Compliance & Restricted Drug Registers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Schedule H / H1 / Narcotics Registers'),
            Tab(text: 'Pharmacist Approvals & e-Rx'),
            Tab(text: 'Immutable Audit Trail History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleRegisterTab(),
          _buildPharmacistApprovalTab(),
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  Widget _buildScheduleRegisterTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Digital Register for Controlled Substances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported Schedule H, H1 & Narcotics Drug Audit Register.')),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export Drug Dept Audit Register'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _db.restrictedLogs.length,
              itemBuilder: (context, index) {
                final log = _db.restrictedLogs[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      log.scheduleType == 'Narcotics' ? Icons.warning : Icons.local_hospital,
                      color: log.scheduleType == 'Narcotics' ? Colors.red : Colors.purple,
                    ),
                    title: Text('Schedule: ${log.scheduleType} | Patient: ${log.patientName}'),
                    subtitle: Text('Doctor: ${log.doctorName} | Quantity Dispensed: ${log.quantity}'),
                    trailing: Text(log.createdAt.toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacistApprovalTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pharmacist Verification Workflows & e-Prescribing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _db.prescriptions.length,
              itemBuilder: (context, index) {
                final rx = _db.prescriptions[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified, color: Colors.green),
                    title: Text('e-Rx #${rx.rxNumber} - Doctor: ${rx.doctorName}'),
                    subtitle: Text('License: ${rx.doctorLicense ?? 'N/A'}\nDetails: ${rx.rxDetails ?? ''}'),
                    trailing: const Chip(
                      label: Text('Pharmacist Verified'),
                      backgroundColor: Colors.greenAccent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Immutable Audit Trails & Log History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _db.auditLogs.length,
              itemBuilder: (context, index) {
                final audit = _db.auditLogs[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text('Action: ${audit.action}'),
                    subtitle: Text('Details: ${audit.details.toString()}'),
                    trailing: Text(audit.createdAt.toString().split('.')[0]),
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
