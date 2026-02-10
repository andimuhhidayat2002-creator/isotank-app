import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/services/api_service.dart';

class IsotankDetailScreen extends StatefulWidget {
  final Map<String, dynamic> isotank;

  const IsotankDetailScreen({super.key, required this.isotank});

  @override
  State<IsotankDetailScreen> createState() => _IsotankDetailScreenState();
}

class _IsotankDetailScreenState extends State<IsotankDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final id = widget.isotank['id'];
      final response = await _apiService.get('/isotanks/$id');
      
      if (mounted) {
        setState(() {
          _detail = response is Map<String, dynamic> ? response : response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching details: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: Text(widget.isotank['iso_number'] ?? 'Isotank Detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? const Center(child: Text('Failed to load details', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('General Information'),
                      _buildInfoCard([
                        _InfoRow(label: 'Category', value: _detail!['tank_category'] ?? 'T75'),
                        _InfoRow(label: 'Owner', value: _detail!['owner'] ?? '-'),
                        _InfoRow(label: 'Product', value: _detail!['product'] ?? '-'),
                        _InfoRow(label: 'Location', value: _detail!['location'] ?? '-'),
                        _InfoRow(label: 'Status', value: _detail!['filling_status_desc'] ?? '-'),
                      ]),
                      const SizedBox(height: 24),
                      
                      if (_detail!['last_inspection_log'] != null) ...[
                        _buildSectionTitle('Last Inspection'),
                        _buildInspectionCard(_detail!['last_inspection_log']),
                        const SizedBox(height: 24),
                      ],

                      if (_detail!['last_maintenance_job'] != null) ...[
                        _buildSectionTitle('Latest Maintenance'),
                        _buildMaintenanceCard(_detail!['last_maintenance_job']),
                        const SizedBox(height: 24),
                      ],

                      if (_detail!['last_vacuum_log'] != null) ...[
                        _buildSectionTitle('Vacuum Status'),
                        _buildVacuumCard(_detail!['last_vacuum_log']),
                        const SizedBox(height: 24),
                      ],

                      _buildSectionTitle('History Logs'),
                      _buildHistoryList(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderSection() {
    final statusColor = _getStatusColor(_detail!['filling_status_code'] ?? '');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inventory_2_rounded, color: statusColor, size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detail!['iso_number'] ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _detail!['filling_status_desc'] ?? 'Unknown Status',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildInspectionCard(Map<String, dynamic> log) {
    final date = DateTime.tryParse(log['created_at'] ?? '') ?? DateTime.now();
    return _buildInfoCard([
      _InfoRow(label: 'Date', value: DateFormat('dd MMM yyyy HH:mm').format(date)),
      _InfoRow(label: 'Inspector', value: log['inspector']?['name'] ?? 'System'),
      _InfoRow(label: 'Condition', value: log['condition'] ?? 'Good'),
      _InfoRow(label: 'Job ID', value: '#${log['job_id'] ?? '-'}'),
    ]);
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> job) {
    return _buildInfoCard([
      _InfoRow(label: 'Status', value: job['status'] ?? '-'),
      _InfoRow(label: 'Type', value: job['type'] ?? 'General'),
      _InfoRow(label: 'Reported', value: job['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(job['created_at'])) : '-'),
    ]);
  }

  Widget _buildVacuumCard(Map<String, dynamic> log) {
    return _buildInfoCard([
      _InfoRow(label: 'Reading', value: '${log['reading'] ?? '-'} ${log['unit'] ?? ''}'),
      _InfoRow(label: 'Timestamp', value: log['reading_datetime'] ?? '-'),
    ]);
  }

  Widget _buildHistoryList() {
    final inspections = _detail!['inspection_logs'] as List? ?? [];
    if (inspections.isEmpty) return const Text('No history available', style: TextStyle(color: Colors.grey));

    return Column(
      children: inspections.map((log) {
        final date = DateTime.tryParse(log['created_at'] ?? '') ?? DateTime.now();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.blue, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inspection - ${log['condition'] ?? 'Done'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd MMM yyyy HH:mm').format(date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String code) {
    switch (code) {
      case 'filled': return Colors.blue;
      case 'ready_to_fill': return Colors.green;
      case 'ongoing_inspection': return Colors.cyan;
      case 'under_maintenance': return Colors.orange;
      case 'waiting_team_calibration': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
