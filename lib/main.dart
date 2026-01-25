import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/providers/auth_provider.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/kayan_theme.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/sync_service.dart';
import 'ui/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize offline services
  final connectivity = ConnectivityService();
  await connectivity.initialize();
  
  final sync = SyncService();
  sync.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'KAYAN LNG - Isotank Management',
        debugShowCheckedModeBanner: false,
        theme: KayanTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check auth state
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }
    
    return const LoginScreen();
  }
}
