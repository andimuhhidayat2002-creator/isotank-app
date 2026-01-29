import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/sync_service.dart';
import '../../../logic/providers/auth_provider.dart';
import 'dart:async';
import '../../../data/services/connectivity_service.dart';
import 'inspector_jobs_screen.dart'; // We will move the jobs list here
import 'yard_search_screen.dart';   // We will create this
import 'isotank_search_screen.dart';

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
    
    // Listen to connection changes
    _connectionSubscription = _connectivityService.connectionStatus.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline) {
          _performAutoSync();
        }
      }
    });

    // Initial check (if already online, maybe sync pending)
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
      
      if (mounted) {
        if (_pendingCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Data synced successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Sync incomplete. $_pendingCount items remaining.'), backgroundColor: Colors.orange),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Create profile directory if not exists
              Navigator.pushNamed(context, '/profile'); 
            },
            tooltip: 'Profile & Signature',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface, // Clean background
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            Card(
              color: _isOnline ? Colors.green.withOpacity(0.05) : colorScheme.errorContainer.withOpacity(0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _isOnline ? Colors.green.withOpacity(0.2) : colorScheme.error.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(_isOnline ? Icons.wifi : Icons.wifi_off, 
                         color: _isOnline ? Colors.green : colorScheme.error),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isOnline ? 'ONLINE Mode' : 'OFFLINE Mode', 
                             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_pendingCount > 0 ? '$_pendingCount items pending sync' : 'All data synced',
                             style: theme.textTheme.bodySmall?.copyWith(
                               color: _pendingCount > 0 ? Colors.orange : theme.textTheme.bodySmall?.color
                             )),
                      ],
                    ),
                    const Spacer(),
                    if (_pendingCount > 0 && _isOnline)
                      IconButton(
                        icon: Icon(Icons.sync, color: colorScheme.primary),
                        onPressed: _performAutoSync,
                        tooltip: 'Sync Now',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _MenuCard(
                    title: 'Isotank Lookup',
                    icon: Icons.manage_search, // Icon changed to something different from Yard positioning
                    color: Colors.indigo, // New color for distinction
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const IsotankSearchScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    title: 'My Inspections',
                    icon: Icons.assignment,
                    color: colorScheme.primary, // Industrial Blue
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InspectorJobsScreen()),
                      ).then((_) => _updatePendingCount());
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    title: 'Yard Positioning',
                    icon: Icons.map,
                    color: const Color(0xFFFF6B35), // KayanColors.orange
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const YardMapScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    title: 'Download Offline Data',
                    icon: Icons.download_for_offline,
                    color: Colors.green, // Success
                    onTap: () async {
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator()),
                      );
                      
                      try {
                        await _syncService.downloadOfflineData();
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Data downloaded for offline use!'), backgroundColor: Colors.green),
                          );
                          _updatePendingCount();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Sync failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1), // Subtle border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
