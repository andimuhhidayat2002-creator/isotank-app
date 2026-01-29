import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class IsotankDetailView extends StatefulWidget {
  final int isotankId;

  const IsotankDetailView({super.key, required this.isotankId});

  @override
  State<IsotankDetailView> createState() => _IsotankDetailViewState();
}

class _IsotankDetailViewState extends State<IsotankDetailView> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.getIsotankDetail(widget.isotankId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Isotank Detail'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Conditions'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data ?? {};
            return TabBarView(
              children: [
                _buildOverviewTab(data),
                _buildConditionsTab(data),
                _buildHistoryTab(data),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data) {
    // Maintenance Check
    final bool hasMaintenance = data['has_active_maintenance'] ?? false;
    final List<dynamic> maintenanceJobs = data['active_maintenance_jobs'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasMaintenance) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Maintenance Required',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (maintenanceJobs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...maintenanceJobs.map((job) => Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: Text(
                        '• ${job['source_item'] ?? 'General'}: ${job['description'] ?? '-'}',
                        style: TextStyle(color: Colors.red[800], fontSize: 13),
                      ),
                    )),
                  ]
                ],
              ),
            ),
          ],
          
          _buildSummaryChip(data),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Technical Specs',
            icon: Icons.settings_suggest,
            children: [
              _buildInfoRow(Icons.business, 'Owner', data['owner'] ?? '-'),
              _buildInfoRow(Icons.category, 'Product', data['product'] ?? '-'),
              _buildInfoRow(Icons.location_on, 'Location', data['location'] ?? '-'),
              // Calibration
              _buildInfoRow(
                Icons.calendar_today, 
                'Last Calibration', 
                data['latest_class_survey'] != null 
                  ? (data['latest_class_survey']['survey_date'] ?? '-').toString().split('T')[0]
                  : '-',
              ),
              _buildInfoRow(
                Icons.local_gas_station, 
                'Filling Status', 
                (data['filling_status_desc'] ?? data['filling_status_code'] ?? 'Unknown').toUpperCase(),
                valueColor: _getFillingColor(data['filling_status_code']),
              ),
              _buildInfoRow(
                Icons.check_circle, 
                'Global Status', 
                (data['status'] ?? 'Inactive').toUpperCase(),
                valueColor: data['status'] == 'active' ? Colors.green : Colors.red,
              ),
              if (data['manufacturer'] != null)
                _buildInfoRow(Icons.factory_outlined, 'Manufacturer', data['manufacturer']),
              if (data['capacity'] != null)
                _buildInfoRow(Icons.straighten, 'Capacity', data['capacity']),
            ],
          ),
          const SizedBox(height: 16),
          _buildLastInspectionSummary(data),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ISO NUMBER',
                style: TextStyle(color: Colors.blue[100], fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['tank_category'] ?? 'T75',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['iso_number'] ?? '-',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsTab(Map<String, dynamic> data) {
    final List<dynamic> itemStatuses = data['item_statuses'] ?? data['itemStatuses'] ?? [];
    
    if (itemStatuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No condition data available yet.'),
            const SizedBox(height: 8),
            Text('Debug Keys: ${data.keys.toList().join(", ")}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _buildGroupedItems(itemStatuses).length,
      itemBuilder: (context, index) {
          final item = _buildGroupedItems(itemStatuses)[index];
          
          if (item['type'] == 'header') {
            return Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50], // Light background for header
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blueGrey[100]!),
              ),
              child: Text(
                _getCategoryTitle(item['title']),
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.blueGrey[800],
                  letterSpacing: 0.5
                ),
              ),
            );
          }
        
          final bool isAttr = (item['item_name'] ?? '').toString().contains('_attr_');
          
          if (isAttr) {
             return Padding(
               padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4), // Adjusted padding
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Expanded(
                     child: Text(
                       item['description'] ?? '', 
                       style: const TextStyle(fontSize: 13, color: Colors.grey),
                     ),
                   ),
                   Text(
                     item['condition'] ?? '',
                     style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                   ),
                 ],
               ),
             );
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8, top: 4), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: ListTile(
              dense: true, // Make it compact
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              title: Text(
                _cleanLabel(item['description'] ?? item['item_name'] ?? '-'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              trailing: _buildConditionBadge(item['condition']),
            ),
          );
      },
    );
  }

  // Helper to Flatten Groups into a List [Header, Item, Item, Header, Item...]
  List<Map<String, dynamic>> _buildGroupedItems(List<dynamic> items) {
    // We need to maintain insertion order but grouped.
    // The items generally come sorted by order from backend.
    
    final Map<String, List<Map<String, dynamic>>> groups = {};
    String lastCategory = 'General'; 
    
    // We need a map to remember the category of each item to assign its attributes correctly
    final Map<String, String> itemCodeToCategory = {};

    for (var item in items) {
      String code = (item['item_name'] ?? '').toString().toLowerCase();
      String label = (item['description'] ?? '').toString().toLowerCase();
      String cat = 'B. GENERAL CONDITION'; // Default
      
      // ATTRIBUTE HANDLING
      if (code.contains('_attr_')) {
          // Extract parent code: 'psv1_condition_attr_sn' -> 'psv1_condition'
          // Simple split by first _attr_
          String parentCode = code.split('_attr_')[0];
          // Try to look up parent's category. If valid, use it. If not, use lastCategory.
          if (itemCodeToCategory.containsKey(parentCode)) {
             cat = itemCodeToCategory[parentCode]!;
          } else {
             cat = lastCategory;
          }
           groups.putIfAbsent(cat, () => []).add(item);
           continue;
      }

      // --- T11 / T50 MAPPING (Explicit by Code) ---
      if (code.startsWith('t11_a') || code.startsWith('t50_a')) cat = 'A. FRONT';
      else if (code.startsWith('t11_b') || code.startsWith('t50_b')) cat = 'B. REAR';
      else if (code.startsWith('t11_c') || code.startsWith('t50_c')) cat = 'C. RIGHT'; 
      else if (code.startsWith('t11_d') || code.startsWith('t50_d')) cat = 'D. LEFT';
      else if (code.startsWith('t11_e') || code.startsWith('t50_e')) cat = 'E. TOP';
      else if (code.startsWith('t11_f') || code.startsWith('t50_f')) cat = 'F. INTERIOR / OTHER';
      
      // --- T75 Mapping (Standard) ---
      else {
          // G. PSV
          if (_matches(code, label, ['psv', 'relief', 'safety valve'])) {
            cat = 'G. PSV (PRESSURE SAFETY VALVES)';
          }
          // F. VACUUM
          else if (_matches(code, label, ['vacuum', 'rupture', 'port suction'])) {
             cat = 'F. VACUUM SYSTEM';
          }
           // D. IBOX
          else if (_matches(code, label, ['ibox', 'battery'])) {
            cat = 'D. IBOX SYSTEM';
          }
          // E. INSTRUMENTS
          else if (_matches(code, label, ['gauge', 'thermometer', 'remote', 'manometer', 'reading ('])) {
                cat = 'E. INSTRUMENTS';
          }
          // C. VALVES & PIPING
          else if (_matches(code, label, ['valve', 'pipe', 'joint', 'flange', 'coupling', 'dust', 'esdv', 'connection', 'syphon', 'adapter', 'blind', 'air_source', 'regulator'])) {
            cat = 'C. VALVES & PIPING';
          }
          // B. GENERAL
          else if (_matches(code, label, ['surface', 'frame', 'plate', 'sticker', 'label', 'document', 'walkway', 'ladder', 'venting', 'explosion', 'grounding', 'gps', 'antenna', 'heating', 'cap', 'cladding'])) {
            cat = 'B. GENERAL CONDITION';
          }
      }
      
      // Override for specific tricky items
      if (code.contains('valve_box')) cat = 'C. VALVES & PIPING'; 
      
      // Store decision
      itemCodeToCategory[code] = cat;
      lastCategory = cat;
      groups.putIfAbsent(cat, () => []).add(item);
    }
    
    // Flatten
    List<Map<String, dynamic>> flatList = [];
    var sortedKeys = groups.keys.toList()..sort();
    
    for (var key in sortedKeys) {
      flatList.add({'type': 'header', 'title': key});
      flatList.addAll(groups[key]!);
    }
    
    return flatList;
  }

  bool _matches(String code, String label, List<String> keywords) {
    for (var k in keywords) {
      if (code.contains(k) || label.contains(k)) return true;
    }
    return false;
  }

  String _getCategoryTitle(String key) {
      return key; // Already formatted in the map logic
  }
      
  Widget _buildListStub() { // Placeholder to close syntax if needed... but we are replacing the ListView.builder block.
    return Container(); 
  }



  Widget _buildHistoryTab(Map<String, dynamic> data) {
    final List<dynamic> inspections = data['inspection_logs'] ?? data['inspectionLogs'] ?? [];
    final List<dynamic> maintenance = data['maintenance_jobs'] ?? data['maintenanceJobs'] ?? [];

    if (inspections.isEmpty && maintenance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No activity history found.'),
            const SizedBox(height: 8),
            Text('Debug Keys: ${data.keys.toList().join(", ")}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (inspections.isNotEmpty) ...[
          const Text('Recent Inspections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...inspections.map((ins) => _buildHistoryCard(
            title: ins['inspection_type']?.toString().toUpperCase() ?? 'INSPECTION',
            subtitle: 'By: ${ins['inspector']?['name'] ?? 'System'}',
            date: (ins['inspection_date'] ?? ins['created_at']).toString().split('T')[0],
            icon: Icons.fact_check,
            color: Colors.blue,
          )),
        ],
        if (maintenance.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Recent Maintenance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...maintenance.map((m) => _buildHistoryCard(
            title: m['work_order_number'] ?? 'Maintenance',
            subtitle: m['status']?.toString().toUpperCase() ?? '-',
            date: (m['created_at']).toString().split('T')[0],
            icon: Icons.build_circle,
            color: Colors.orange,
          )),
        ],
      ],
    );
  }

  Widget _buildLastInspectionSummary(Map<String, dynamic> data) {
    final lastLog = data['last_inspection_log'] ?? data['lastInspectionLog'];
    if (lastLog == null) return const SizedBox.shrink();

    // Format Vacuum
    String vacuumStr = '-';
    if (lastLog['vacuum_value'] != null) {
      try {
        double val = double.parse(lastLog['vacuum_value'].toString());
        vacuumStr = val.toStringAsFixed(1);
      } catch (e) {
        vacuumStr = lastLog['vacuum_value'].toString();
      }
    }

    return _buildInfoCard(
      title: 'Last Inspection Results',
      subtitle: '${(lastLog['inspection_date'] ?? lastLog['created_at']).toString().split('T')[0]} by ${lastLog['inspector']?['name'] ?? '-'}',
      icon: Icons.analytics,
      children: [
        _buildMetricGrid([
          _MetricItem('Vacuum', '$vacuumStr ${lastLog['vacuum_unit'] ?? ''}', Icons.speed),
          _MetricItem('Pressure', '${lastLog['pressure_1'] ?? '-'} MPa', Icons.compress),
          _MetricItem('Level', '${lastLog['level_1'] ?? '-'} mm', Icons.layers_outlined),
        ]),
      ],
    );
  }

  Widget _buildInfoCard({required String title, String? subtitle, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricGrid(List<_MetricItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1,
      children: items.map((item) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 24, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(item.label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      )).toList(),
    );
  }

  Widget _buildHistoryCard({required String title, required String subtitle, required String date, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  String _cleanLabel(String label) {
    return label.replaceFirst(RegExp(r'^(FRONT|REAR|RIGHT|LEFT|TOP): '), '');
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[300]),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildConditionBadge(String? condition) {
    final status = (condition ?? 'na').toLowerCase();
    Color color = Colors.grey;
    if (status == 'good') color = Colors.green;
    else if (status == 'not_good' || status == 'repair') color = Colors.red;
    else if (status == 'need_attention') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _getFillingColor(String? status) {
    status = (status ?? '').toLowerCase();
    if (status.contains('filled')) return Colors.blue;
    if (status.contains('empty') || status.contains('ready')) return Colors.green;
    if (status.contains('inspection') || status.contains('ongoing')) return Colors.orange;
    if (status.contains('maintenance')) return Colors.red;
    return Colors.grey;
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  _MetricItem(this.label, this.value, this.icon);
}
