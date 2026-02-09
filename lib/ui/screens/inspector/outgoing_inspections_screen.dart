import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../inspection_form/inspection_form_screen.dart';

class OutgoingInspectionsScreen extends StatefulWidget {
  const OutgoingInspectionsScreen({super.key});

  @override
  State<OutgoingInspectionsScreen> createState() => _OutgoingInspectionsScreenState();
}

class _OutgoingInspectionsScreenState extends State<OutgoingInspectionsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = _apiService.getInspectorJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outgoing Inspections'),
        backgroundColor: const Color(0xFFF59E0B),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: _loadJobs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allJobs = snapshot.data ?? [];
          
          // Filter ONLY outgoing inspections
          final outgoingJobs = allJobs.where((job) {
            final activityType = job['activity_type']?.toString().toLowerCase() ?? '';
            return activityType.contains('outgoing') || activityType == 'inspection_outgoing';
          }).toList();
          
          if (outgoingJobs.isEmpty) {
            return const Center(
              child: Text(
                'No outgoing inspections found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return _InspectionList(jobs: outgoingJobs, onRefresh: _loadJobs);
        },
      ),
    );
  }
}

class _InspectionList extends StatefulWidget {
  final List<dynamic> jobs;
  final VoidCallback onRefresh;

  const _InspectionList({required this.jobs, required this.onRefresh});

  @override
  State<_InspectionList> createState() => _InspectionListState();
}

class _InspectionListState extends State<_InspectionList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = widget.jobs.where((job) {
      final iso = job['isotank']?['iso_number']?.toString().toUpperCase() ?? '';
      return iso.contains(_query.toUpperCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search Isotank',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFF59E0B)),
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() => _query = val);
            },
          ),
        ),
        Expanded(
          child: filteredJobs.isEmpty
              ? const Center(child: Text('No matching isotanks.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    final isotank = job['isotank'] ?? {};
              
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          isotank['iso_number'] ?? 'Unknown ISO',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                const Text(
                                  'OUTGOING',
                                  style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  'Planned: ${job['planned_date'] != null ? job['planned_date'].toString().split('T')[0] : 'N/A'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            if (job['destination'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.near_me, size: 16, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text('To: ${job['destination']}', style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InspectionFormScreen(jobId: job['id']),
                            ),
                          ).then((_) => widget.onRefresh());
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
