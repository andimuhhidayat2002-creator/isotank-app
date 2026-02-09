import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/sync_service.dart';
import '../../../logic/providers/auth_provider.dart';
import 'dart:async';
import '../../../data/services/connectivity_service.dart';
import 'inspector_jobs_screen.dart';
import 'incoming_inspections_screen.dart';
import 'outgoing_inspections_screen.dart';
import 'yard_search_screen.dart';
import 'isotank_lookup_screen.dart';
import '../maintenance/maintenance_dashboard.dart';

class InspectorDashboard extends StatefulWidget {
  const InspectorDashboard({super.key});

  @override
  State<InspectorDashboard> createState() => _InspectorDashboardState();
}

class _InspectorDashboardState extends State<InspectorDashboard> {
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectionSubscription;
  bool _isOnline = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivityService.isOnline;
    _updatePendingCount();
    
    _connectionSubscription = _connectivityService.connectionStatus.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) _performAutoSync();
      }
    });

    if (_isOnline) {
      _performAutoSync();
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updatePendingCount() async {
    final count = await _syncService.getPendingCount();
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _performAutoSync() async {
    await _updatePendingCount();
    if (_pendingCount > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📡 Connection restored. Syncing pending data...'), backgroundColor: Colors.orange),
        );
      }
      
      await _syncService.syncPendingData();
      await _updatePendingCount();
      
      if (mounted && _pendingCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data synced successfully!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.user?['name'] ?? 'Team';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card - Premium Look
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOnline ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.wifi : Icons.wifi_off, 
                    color: _isOnline ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline ? 'ONLINE Mode' : 'OFFLINE Mode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        _pendingCount > 0 ? '$_pendingCount items pending sync' : 'All data synced',
                        style: TextStyle(
                          color: _pendingCount > 0 ? Colors.orange : Colors.grey[400],
                          fontSize: 14
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_pendingCount > 0 && _isOnline)
                    IconButton(
                      icon: const Icon(Icons.sync, color: Colors.blue),
                      onPressed: _performAutoSync,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Welcome Back, $userName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an operation category to begin.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            
            const SizedBox(height: 24),
            
            // Menu Cards
            _MenuCard(
              title: 'Isotank Lookup',
              subtitle: 'Search isotank details',
              icon: Icons.manage_search,
              color: const Color(0xFF3B82F6), // Blue
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IsotankLookupScreen()),
                );
              },
            ),
            _MenuCard(
              title: 'Incoming Inspections',
              subtitle: 'Check in newly arrived tanks',
              icon: Icons.login_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncomingInspectionsScreen()),
                ).then((_) => _updatePendingCount());
              },
            ),
            _MenuCard(
              title: 'Outgoing Inspections',
              subtitle: 'Final check before dispatch',
              icon: Icons.logout_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OutgoingInspectionsScreen()),
                ).then((_) => _updatePendingCount());
              },
            ),
            _MenuCard(
              title: 'Maintenance',
              subtitle: 'Jobs, Vacuum, Calibration',
              icon: Icons.handyman,
              color: const Color(0xFF8B5CF6), // Violet
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MaintenanceDashboard()),
                );
              },
            ),
            _MenuCard(
              title: 'Yard Positioning',
              icon: Icons.map,
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const YardMapScreen()),
                );
              },
            ),
            _MenuCard(
              title: 'Download Offline Data',
              icon: Icons.download_for_offline,
              color: const Color(0xFF6366F1),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                );
                
                try {
                  await _syncService.downloadOfflineData();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Offline data updated successfully!'), backgroundColor: Colors.green),
                    );
                    _updatePendingCount();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Download failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              color: Colors.white.withOpacity(0.03),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
