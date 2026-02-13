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
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Operations Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Status Card (~90) + Welcome (~80) + Padding (~60)
          const double headerHeight = 260;
          final double availableHeight = constraints.maxHeight - headerHeight;
          
          // We have 3 rows
          final double cardHeight = (availableHeight / 3) - 16; // 16 for mainAxisSpacing
          final double cardWidth = (constraints.maxWidth - 40 - 16) / 2; // horizontal padding 20*2, spacing 16
          
          // Ensure ratio is reasonable (limit to avoid too stretched/squashed)
          double ratio = cardWidth / cardHeight;
          if (ratio < 0.7) ratio = 0.7;
          if (ratio > 1.3) ratio = 1.3;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _isOnline ? const Color(0xFF064E3B).withOpacity(0.3) : const Color(0xFF7F1D1D).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOnline ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off, 
                        color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnline ? 'ONLINE Mode' : 'OFFLINE Mode',
                              style: TextStyle(
                                color: _isOnline ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                fontWeight: FontWeight.bold, 
                                fontSize: 15
                              ),
                            ),
                            Text(
                              _pendingCount > 0 ? '$_pendingCount items pending sync' : 'All data synced',
                              style: TextStyle(
                                color: _isOnline ? const Color(0xFF10B981).withOpacity(0.8) : const Color(0xFFEF4444).withOpacity(0.8),
                                fontSize: 12
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pendingCount > 0 && _isOnline)
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.blue, size: 20),
                          onPressed: _performAutoSync,
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'Welcome Back, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select an operation category to begin.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                
                const SizedBox(height: 20),
                
                // Grid Menu
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: ratio,
                    physics: const NeverScrollableScrollPhysics(), // Fit exactly
                    children: [
                      _MenuCard(
                        title: 'Isotank Lookup',
                        subtitle: 'Search isotank details',
                        icon: Icons.search,
                        color: const Color(0xFF3B82F6),
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
                        icon: Icons.handyman_rounded,
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MaintenanceDashboard()),
                          );
                        },
                      ),
                      _MenuCard(
                        title: 'Yard Positioning',
                        subtitle: 'Real-time yard layout',
                        icon: Icons.map_rounded,
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
                        subtitle: 'Offline support',
                        icon: Icons.download_for_offline_rounded,
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
                const SizedBox(height: 16),
              ],
            ),
          );
        },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          // Reduced padding to give more space for text
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937), // Card background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Expanded( // Ensure text can take available space
                child: Center( // Center specifically vertically in the expanded area
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Shrink wrap vertically
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14, // Slightly smaller font
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10, // Slightly smaller
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
