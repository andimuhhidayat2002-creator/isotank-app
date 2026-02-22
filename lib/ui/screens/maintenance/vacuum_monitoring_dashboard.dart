import 'package:flutter/material.dart';
import '../../../data/services/vacuum_service.dart';

class VacuumMonitoringDashboard extends StatefulWidget {
  final Function(int) onSelectIsotank;
  const VacuumMonitoringDashboard({super.key, required this.onSelectIsotank});

  @override
  State<VacuumMonitoringDashboard> createState() => _VacuumMonitoringDashboardState();
}

class _VacuumMonitoringDashboardState extends State<VacuumMonitoringDashboard> {
  final VacuumService _service = VacuumService();
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMonitoringSessions();
      if (mounted) {
        setState(() {
          _sessions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dateTime = DateTime.parse(isoDate);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    } catch (e) {
      return isoDate.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: const Text('No monitoring sessions found.'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final isotank = session['isotank'];
          final days = session['days'] as Map<String, dynamic>;
          final isCompleted = session['is_completed'] == true;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                isotank['iso_number'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: isCompleted ? Colors.green[400] : Colors.blue[300]
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Start: ${_formatDate(session['start_date'])}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildProgressDots(days),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'COMPLETED' : 'ONGOING',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.orange
                    ),
                  )
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDayRow('Day 1 (Initial)', days['1']),
                      const Divider(),
                      _buildDayRow('Day 2', days['2']),
                      _buildDayRow('Day 3', days['3']),
                      _buildDayRow('Day 4', days['4']),
                      _buildDayRow('Day 5', days['5']),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => widget.onSelectIsotank(isotank['id']),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('UPDATE VACUUM DATA'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressDots(Map<String, dynamic> days) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final dayNum = (index + 1).toString();
        final hasData = days.containsKey(dayNum);
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasData ? Colors.green[400] : Colors.white10,
            border: Border.all(color: hasData ? Colors.green : Colors.white24),
          ),
        );
      }),
    );
  }

  Widget _buildDayRow(String label, dynamic dayData) {
    if (dayData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            Text('-', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      );
    }

    final isDay1 = (dayData['day_number'] ?? 0) == 1;
    
    // Logic to pick a representative value
    var vacuumValue = '-';
    if (isDay1) {
      final v = dayData['portable_vacuum_when_machine_stops'] ?? dayData['portable_vacuum_value'];
      if (v != null) vacuumValue = v.toString();
    } else {
      final v = dayData['evening_vacuum_value'] ?? dayData['morning_vacuum_value'];
      if (v != null) vacuumValue = v.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Row(
            children: [
              Text(
                vacuumValue, 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)
              ),
              const SizedBox(width: 4),
              const Text('mTorr', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
