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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(_detail?['iso_number'] ?? widget.isotank['iso_number'] ?? 'Detail'),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Condition'),
              Tab(text: 'Inspections'),
              Tab(text: 'Maintenance'),
              Tab(text: 'Calibration'),
              Tab(text: 'Vacuum'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _detail == null
                ? const Center(child: Text('Data not found', style: TextStyle(color: Colors.white)))
                : TabBarView(
                    children: [
                      _buildConditionTab(),
                      _buildInspectionsTab(),
                      _buildMaintenanceTab(),
                      _buildCalibrationTab(),
                      _buildVacuumTab(),
                    ],
                  ),
      ),
    );
  }

  // --- TABS ---

  Widget _buildConditionTab() {
    final log = _detail!['last_inspection_log'];
    final items = _detail!['item_statuses'] as List? ?? [];
    
    // Extract Readings (Pseudo Items in the API response)
    final vacuum = items.firstWhere((it) => it['description'] == 'Vacuum Value', orElse: () => {})['condition'] ?? '-';
    final pressure = items.firstWhere((it) => it['description'] == 'Pressure' || it['description'] == 'Pressure PG', orElse: () => {})['condition'] ?? '-';
    final level = items.firstWhere((it) => it['description'] == 'Level' || it['description'] == 'Level LG', orElse: () => {})['condition'] ?? '-';

    // Grouping
    final Map<String, List<dynamic>> groupedItems = {};
    for (var item in items) {
      if (item['is_attribute'] == true) continue;
      String cat = _getCategoryLabel(item['category']?.toString() ?? 'other', _detail!['tank_category'] ?? 'T75');
      groupedItems.putIfAbsent(cat, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 20),
          
          if (log != null) ...[
            _buildSectionHeader('Last Inspection: ${DateFormat('dd MMM yyyy').format(DateTime.parse(log['created_at']))}'),
            Text('Inspector: ${log['inspector']?['name'] ?? 'System'}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 12),
            
            // Readings Box (Match Web Style)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildReadingRow('Vacuum', vacuum),
                  _buildReadingRow('Pressure', pressure),
                  _buildReadingRow('Level', level),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          _buildSectionHeader('Items Condition'),
          ...groupedItems.entries.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: Colors.white.withOpacity(0.05),
                  child: Text(group.key, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                ...group.value.map((it) => _buildItemConditionRow(it['description'], it['condition'])),
                const SizedBox(height: 12),
              ],
            );
          }),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInspectionsTab() {
    final logs = _detail!['inspection_logs'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final date = DateTime.parse(log['created_at']);
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(DateFormat('dd MMM yyyy HH:mm').format(date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Inspector: ${log['inspector']?['name'] ?? 'N/A'}\nCondition: ${log['condition'] ?? 'Done'}', style: TextStyle(color: Colors.grey[400])),
            trailing: const Icon(Icons.description_outlined, color: Colors.blueAccent),
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceTab() {
    final jobs = _detail!['maintenance_jobs'] as List? ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(job['source_item'] ?? job['type'] ?? 'Maintenance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${job['status'].toString().toUpperCase()}\nDate: ${job['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(job['created_at'])) : '-'}', style: TextStyle(color: Colors.grey[400])),
            trailing: _buildStatusBadge(job['status']),
          ),
        );
      },
    );
  }

  Widget _buildCalibrationTab() {
    final components = _detail!['components'] as List? ?? [];
    final survey = _detail!['latest_class_survey'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Class Survey Status'),
          if (survey != null)
             _buildInfoCard([
               _InfoRow(label: 'Last Survey', value: survey['survey_date'] ?? '-'),
               _InfoRow(label: 'Expiry Date', value: survey['expiry_date'] ?? '-'),
               _InfoRow(label: 'Certificate', value: survey['certificate_number'] ?? '-'),
             ])
          else
            const Text('No class survey data recorded', style: TextStyle(color: Colors.grey)),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Components & Calibration'),
          if (components.isEmpty)
            const Text('No components registered', style: TextStyle(color: Colors.grey))
          else
            ...components.map((comp) {
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(comp['component_type'] ?? 'Component', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(comp['position_code'] ?? '-', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(label: 'Serial No', value: comp['serial_number'] ?? '-'),
                      _InfoRow(label: 'Cert No', value: comp['certificate_number'] ?? '-'),
                      _InfoRow(label: 'Cal. Date', value: comp['last_calibration_date'] ?? '-'),
                      _InfoRow(label: 'Expiry', value: comp['expiry_date'] ?? '-', valueColor: _isExpired(comp['expiry_date']) ? Colors.red : Colors.green),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVacuumTab() {
    final logs = _detail!['vacuum_logs'] as List? ?? [];
    if (logs.isEmpty) {
      return const Center(child: Text('No vacuum logs recorded', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final v = logs[index];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(v['check_datetime'] ?? '-', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text('${v['vacuum_value_mtorr'] ?? '-'} mTorr', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Temp: ${v['temperature'] ?? '-'} °C', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (v['remarks'] != null) Text(v['remarks'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildOverviewCard() {
    final statusColor = _getStatusColor(_detail!['filling_status_code'] ?? '');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'ISO Number', value: _detail!['iso_number'] ?? '-'),
          _InfoRow(label: 'Owner', value: _detail!['owner'] ?? '-'),
          _InfoRow(label: 'Location', value: _detail!['location'] ?? '-'),
          _InfoRow(label: 'Product', value: _detail!['product'] ?? '-'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filling Status', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    _detail!['filling_status_desc'] ?? '-',
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _InfoRow(label: 'Status', value: _detail!['status']?.toUpperCase() ?? '-'),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          _buildSectionHeader('Technical Specs'),
          _InfoRow(label: 'Manufacturer', value: _detail!['manufacturer'] ?? '-'),
          _InfoRow(label: 'Capacity', value: '${_detail!['capacity'] ?? '-'} L'),
          _InfoRow(label: 'Tare weight', value: '${_detail!['tare_weight'] ?? '-'} Kg'),
          _InfoRow(label: 'Max Gross', value: '${_detail!['max_gross_weight'] ?? '-'} Kg'),
        ],
      ),
    );
  }

  Widget _buildReadingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemConditionRow(String label, String condition) {
    bool isGood = condition.toLowerCase() == 'good' || condition.toLowerCase() == 'active';
    bool isBad = condition.toLowerCase() == 'bad' || condition.toLowerCase() == 'damage';
    
    Color color = Colors.grey;
    if (isGood) color = Colors.greenAccent;
    if (isBad) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
            child: Text(condition.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isClosed = status == 'closed' || status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isClosed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: isClosed ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _getCategoryLabel(String key, String tankCat) {
    final Map<String, Map<String, String>> categoryMap = {
      'T11': {'a': 'A. FRONT', 'b': 'B. REAR', 'c': 'C. RIGHT', 'd': 'D. LEFT', 'e': 'E. TOP', 'other': 'Other / Internal'},
      'T50': {'a': 'A. FRONT OUT SIDE VIEW', 'b': 'B. REAR OUT SIDE VIEW', 'c': 'C. RIGHT SIDE/VALVE BOX', 'd': 'D. LEFT SIDE', 'e': 'E. TOP', 'other': 'Other / Internal'},
      'T75': {'b': 'B. GENERAL CONDITION', 'c': 'C. VALVES & PIPING', 'd': 'D. IBOX SYSTEM', 'e': 'E. INSTRUMENTS', 'f': 'F. VACUUM SYSTEM', 'g': 'G. SAFETY VALVES (PSV)'},
    };
    return categoryMap[tankCat]?[key.toLowerCase()] ?? 'General';
  }

  bool _isExpired(dynamic date) {
    if (date == null || date == '-') return false;
    try {
      final dt = DateTime.parse(date.toString());
      return dt.isBefore(DateTime.now());
    } catch (_) { return false; }
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
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
