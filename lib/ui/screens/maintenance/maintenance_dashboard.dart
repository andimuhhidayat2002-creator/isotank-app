import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../logic/providers/auth_provider.dart';
import 'maintenance_form_screen.dart';
import 'vacuum_form_screen.dart';
import 'calibration_screens.dart';
import 'vacuum_suction_screen.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maintenance & Repair'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Jobs', icon: Icon(Icons.build)),
              Tab(text: 'Vacuum Suction', icon: Icon(Icons.air)),
              Tab(text: 'Calibration', icon: Icon(Icons.speed)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MaintenanceJobsList(),
            VacuumSuctionScreen(),
            CalibrationListScreen(),
          ],
        ),
      ),
    );
  }
}

class MaintenanceJobsList extends StatefulWidget {
  const MaintenanceJobsList({super.key});

  @override
  State<MaintenanceJobsList> createState() => _MaintenanceJobsListState();
}

class _MaintenanceJobsListState extends State<MaintenanceJobsList> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _jobsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  
  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = _apiService.getMaintenanceJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Isotank',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) {
              setState(() => _query = val);
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
      
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
      
              final allJobs = snapshot.data ?? [];
      
              if (allJobs.isEmpty) {
                return const Center(child: Text('No open maintenance jobs.'));
              }
              
              final filteredJobs = allJobs.where((job) {
                 final iso = job['isotank']?['iso_number']?.toString().toUpperCase() ?? '';
                 final status = job['status']?.toString().toLowerCase() ?? '';
                 return status != 'closed' && iso.contains(_query.toUpperCase());
              }).toList();
  
              if (filteredJobs.isEmpty) return const Center(child: Text('No matching jobs.'));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(job['isotank']?['iso_number'] ?? 'Unknown ISO'),
                      subtitle: Text('${job['source_item']} - ${job['description']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: job['status'] == 'open' ? Colors.green[100] : Colors.amber[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job['status'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaintenanceFormScreen(
                              jobId: job['id'],
                              jobData: job,
                            ),
                          ),
                        ).then((value) {
                          if (value == true) _loadJobs();
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
