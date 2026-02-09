import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../logic/providers/auth_provider.dart';
import 'maintenance_form_screen.dart';
import 'vacuum_form_screen.dart';
import 'calibration_screens.dart';
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
              Tab(text: 'Vacuum', icon: Icon(Icons.vibration)),
              Tab(text: 'Calibration', icon: Icon(Icons.speed)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MaintenanceJobsList(),
            VacuumActivitiesList(),
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
                 final status = job['status']?.toString().toLowerCase() ?? ''; // Check status
                 // Filter out closed jobs
                 return status != 'closed' && iso.contains(_query.toUpperCase());
              }).toList();
      
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
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
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
                     ? const Center(child: Text('No matching jobs.'))
                     : ListView.builder(
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
                      ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class VacuumActivitiesList extends StatefulWidget {
  const VacuumActivitiesList({super.key});

  @override
  State<VacuumActivitiesList> createState() => _VacuumActivitiesListState();
}

class _VacuumActivitiesListState extends State<VacuumActivitiesList> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _vacuumFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadActivities() {
    setState(() {
      _vacuumFuture = _apiService.getVacuumActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _vacuumFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allActivities = snapshot.data ?? [];

        if (allActivities.isEmpty) {
          return const Center(child: Text('No active vacuum suction.'));
        }

        final filteredActivities = allActivities.where((activity) {
           final iso = activity['isotank']?['iso_number']?.toString().toUpperCase() ?? '';
           return iso.contains(_query.toUpperCase());
        }).toList();

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
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
              child: filteredActivities.isEmpty 
               ? const Center(child: Text('No matching activities.'))
               : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = filteredActivities[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(activity['isotank']?['iso_number'] ?? 'Unknown ISO'),
                        subtitle: Text('Day ${activity['day_number']} - ${activity['created_at'].toString().split('T')[0]}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VacuumFormScreen(
                                activityId: activity['id'],
                                activityData: activity,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) _loadActivities();
                          });
                        },
                      ),
                    );
                  },
                ),
            ),
          ],
        );
      },
    );
  }
}
