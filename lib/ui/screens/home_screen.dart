import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import 'inspector/inspector_dashboard.dart';
import 'maintenance/maintenance_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'receiver/receiver_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final normalizedRole = role?.toLowerCase() ?? '';

    if (normalizedRole == 'inspector') {
      return const InspectorDashboard();
    }
    
    // Unified Dashboard: Direct Maintenance users to InspectorDashboard
    if (normalizedRole == 'maintenance') {
      return const InspectorDashboard();
    }

    if (normalizedRole == 'receiver') {
      return const ReceiverDashboard();
    }

    if (normalizedRole == 'admin' || normalizedRole == 'management') {
      return const AdminDashboard();
    }
    
    // FALLBACK: If role is unknown, default to InspectorDashboard
    // This prevents users from being stuck on a blank screen
    return const InspectorDashboard();
    
    /* Placeholder removed to ensure login always succeeds */
    /*
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isotank System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${authProvider.user?['name']}'),
            Text('Role: $role'),
            const SizedBox(height: 20),
             if (role == 'maintenance') 
               FilledButton.icon(
                 onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const MaintenanceDashboard()),
                   );
                 },
                 icon: const Icon(Icons.build),
                 label: const Text('Go to Maintenance Dashboard'),
               )
             else 
               const Text('Dashboard under construction for this role'),
          ],
        ),
      ),
    );
  }
}
