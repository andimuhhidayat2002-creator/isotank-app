import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../logic/providers/auth_provider.dart';
import 'signature_pad_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _signatureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Current user data is in AuthProvider, but signature URL comes effectively from there too if updated.
    // However, the standard auth user object might not have the latest signature path if it was just changed elsewhere.
    // For now, we trust the AuthProvider user data or fetch fresh if needed.
    // Let's assume AuthProvider needs an update or we fetch "me" from API.
    
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      
      // If the user object has signature_path (requires update to AuthProvider/User model mapping)
      // or we can just fetch it fresh.
      final api = ApiService();
      final response = await api.get('/me');
      
      if (response['success'] == true) {
        final userData = response['user'];
        // Ideally update AuthProvider here too
        
        setState(() {
          _signatureUrl = userData['signature_path'] != null 
              ? '${api.baseUrl.replaceAll('/api', '')}/storage/${userData['signature_path']}'
              : null;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadSignature(File file) async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      // Using Multipart request manually or if ApiService supports it
      // Let's assume we need to implement multipart in ApiService or do it here.
      // Since ApiService usually handles JSON, we might need a specific upload method.
      // For now, I'll rely on the assumption that ApiService has a postMultipart or similar, 
      // OR I will implement a standard http multipart request.
      
      final response = await api.uploadProfileSignature(file);
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature updated successfully')),
        );
        _loadProfile(); // Reload to see new signature
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update signature: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             // Profile Header
             CircleAvatar(
               radius: 50,
               backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
               child: Text(
                 user?['name']?[0] ?? '?',
                 style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor),
               ),
             ),
             const SizedBox(height: 16),
             Text(
               user?['name'] ?? 'Unknown User',
               style: Theme.of(context).textTheme.headlineSmall,
             ),
             Text(
               user?['email'] ?? '-',
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
             ),
             const SizedBox(height: 8),
             Chip(label: Text((user?['role'] ?? 'User').toUpperCase())),
             
             const Divider(height: 40),
             
             // Digital Signature Section
             ListTile(
               title: const Text('Digital Signature'),
               subtitle: const Text('Used for inspection reports verification'),
               trailing: IconButton(
                 icon: const Icon(Icons.edit),
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => SignaturePadScreen(
                       onSaved: _uploadSignature,
                     )),
                   );
                 },
               ),
             ),
             
             const SizedBox(height: 10),
             
             Container(
               height: 150,
               width: double.infinity,
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[300]!),
                 borderRadius: BorderRadius.circular(8),
                 color: Colors.grey[50],
               ),
               alignment: Alignment.center,
               child: _signatureUrl != null
                   ? Image.network(
                       _signatureUrl!,
                       fit: BoxFit.contain,
                       loadingBuilder: (ctx, child, progress) {
                         if (progress == null) return child;
                         return const CircularProgressIndicator();
                       },
                       errorBuilder: (ctx, err, stack) => const Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.broken_image, color: Colors.grey),
                           Text('Error loading signature'),
                         ],
                       ),
                     )
                   : const Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.create, color: Colors.grey),
                         Text('No signature set'),
                         Text('Tap edit to draw', style: TextStyle(fontSize: 10, color: Colors.grey)),
                       ],
                     ),
             ),
             
             if (_isLoading)
               const Padding(
                 padding: EdgeInsets.only(top: 20),
                 child: CircularProgressIndicator(),
               ),
          ],
        ),
      ),
    );
  }
}
