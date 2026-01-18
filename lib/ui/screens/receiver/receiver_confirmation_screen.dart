import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../data/services/receiver_service.dart';
import '../../../data/services/file_manager_service.dart';

class ReceiverConfirmationScreen extends StatefulWidget {
  final int jobId;

  const ReceiverConfirmationScreen({super.key, required this.jobId});

  @override
  State<ReceiverConfirmationScreen> createState() => _ReceiverConfirmationScreenState();
}

class _ReceiverConfirmationScreenState extends State<ReceiverConfirmationScreen> {
  final ReceiverService _receiverService = ReceiverService();
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, TextEditingController> _remarkControllers = {};
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _inspectionData;
  final Map<String, String> _decisions = {}; // itemKey -> 'ACCEPT' or 'REJECT'
  final Map<String, String?> _photoPaths = {}; // itemKey -> photo path or XFile path
  final Map<String, XFile?> _photoFiles = {}; // itemKey -> XFile (for web)

  // 10 General Condition Items
  // 10 General Condition Items (REMOVED: Now loaded dynamically from API)
  // static const List<Map<String, String>> _generalConditionItems = [...];

  @override
  void initState() {
    super.initState();
    _loadInspection();
  }

  // Helper to get items safely
  List<dynamic> get _dynamicItems => (_inspectionData?['items'] as List?) ?? [];

  @override
  void dispose() {
    for (var controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInspection() async {
    try {
      final data = await _receiverService.getInspectionForReceiver(widget.jobId);
      setState(() {
        _inspectionData = data;
        _isLoading = false;
        
        // Initialize controllers for dynamic items
        final items = data['items'] as List;
        for (var item in items) {
            final key = item['key'];
            if (!_remarkControllers.containsKey(key)) {
                _remarkControllers[key] = TextEditingController();
            }
        }

        // Check if already confirmed
        if (data['already_confirmed'] == true) {
          _showAlreadyConfirmedDialog();
        }
      });
    } catch (e) {
      // Error handling...
      setState(() => _isLoading = false);
    }
  }


  Future<void> _pickPhoto(String itemKey) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photoFiles[itemKey] = image;
          _photoPaths[itemKey] = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _removePhoto(String itemKey) {
    setState(() {
      _photoFiles[itemKey] = null;
      _photoPaths[itemKey] = null;
    });
  }


  bool _validateConfirmations() {
    // Check if all items have a decision
    for (var item in _dynamicItems) {
      final key = item['key'];
      if (!_decisions.containsKey(key) || _decisions[key] == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitConfirmations() async {
    if (!_validateConfirmations()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please make a decision (ACCEPT or REJECT) for all items.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build confirmations map
      final Map<String, Map<String, dynamic>> confirmations = {};
      
      for (var item in _dynamicItems) {
        final itemKey = item['key']!;
        confirmations[itemKey] = {
          'decision': _decisions[itemKey]!,
          'remark': _remarkControllers[itemKey]?.text.trim().isNotEmpty == true
              ? _remarkControllers[itemKey]!.text.trim() 
              : null,
          'photo': _photoFiles[itemKey] ?? _photoPaths[itemKey],
        };
      }

      final result = await _receiverService.submitConfirmations(widget.jobId, confirmations);

      setState(() => _isSubmitting = false);

      if (mounted) {
        final allAccepted = result['data']?['all_accepted'] ?? false;
        final message = result['message'] ?? 'Confirmation submitted successfully';
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(allAccepted ? 'All Items Accepted ✓' : 'Some Items Rejected'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit confirmations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAlreadyConfirmedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Already Confirmed'),
        content: const Text('This inspection has already been confirmed and cannot be modified.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String? condition) {
    switch (condition) {
      case 'good':
        return Colors.green;
      case 'not_good':
        return Colors.red;
      case 'need_attention':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getConditionIcon(String? condition) {
    switch (condition) {
      case 'good':
        return Icons.check_circle;
      case 'not_good':
        return Icons.cancel;
      case 'need_attention':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  Widget _buildItemCard(Map<String, String> item, int index) {
    final itemKey = item['key']!;
    final itemName = item['name']!;
    
    // Get inspector condition from inspection data
    final items = _inspectionData?['items'] as List? ?? [];
    final itemData = items.firstWhere(
      (i) => i['key'] == itemKey,
      orElse: () => {'inspector_condition': 'na', 'inspector_condition_formatted': 'N/A'},
    );
    final inspectorCondition = itemData['inspector_condition'] ?? 'na';
    final inspectorConditionFormatted = itemData['inspector_condition_formatted'] ?? 'N/A';
    
    final decision = _decisions[itemKey];
    final photoPath = _photoPaths[itemKey];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0D47A1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Inspector Condition (Read-Only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getConditionColor(inspectorCondition).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getConditionColor(inspectorCondition),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getConditionIcon(inspectorCondition),
                    color: _getConditionColor(inspectorCondition),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Inspector: $inspectorConditionFormatted',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _getConditionColor(inspectorCondition),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Decision Buttons
            const Text(
              'Your Decision:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _decisions[itemKey] = 'ACCEPT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: decision == 'ACCEPT' ? Colors.green : Colors.grey[300],
                      foregroundColor: decision == 'ACCEPT' ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _decisions[itemKey] = 'REJECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: decision == 'REJECT' ? Colors.red : Colors.grey[300],
                      foregroundColor: decision == 'REJECT' ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Remark (Optional)
            TextField(
              controller: _remarkControllers[itemKey],
              decoration: const InputDecoration(
                labelText: 'Remark (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add your remark here...',
              ),
              maxLines: 2,
              maxLength: 500,
            ),
            const SizedBox(height: 12),

            // Photo (Optional)
            if (photoPath != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: photoPath.startsWith('blob:') || photoPath.startsWith('http')
                            ? Image.network(
                                photoPath,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Text('Could not load image'),
                              )
                            : kIsWeb
                                ? const SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: Center(child: Text('Local file hidden on Web')),
                                  )
                                : Image.file(
                                    File(photoPath),
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Text('Could not load image'),
                                  ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => _removePhoto(itemKey),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            OutlinedButton.icon(
              onPressed: () => _pickPhoto(itemKey),
              icon: const Icon(Icons.camera_alt),
              label: Text(photoPath != null ? 'Change Photo' : 'Add Photo (Optional)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receiver Confirmation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_inspectionData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receiver Confirmation')),
        body: const Center(child: Text('Failed to load inspection')),
      );
    }

    final job = _inspectionData!['job'] ?? {};
    final isotank = _inspectionData!['isotank'] ?? {};
    final destination = _inspectionData!['destination'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receiver Confirmation'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Column(
        children: [
          // Header Card (Item A - Enhanced)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50], // Light blue for visibility
              border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${isotank['iso_number'] ?? 'Unknown ISO'}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isotank['filling_status_desc'] ?? 'Status N/A',
                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, 'Destination', '$destination'),
                _buildInfoRow(Icons.person, 'Inspector', '${_inspectionData!['inspector']?['name'] ?? 'N/A'}'),
                _buildInfoRow(Icons.calendar_today, 'Date', '${_inspectionData!['inspection_date'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                // Enhanced Info
                Row(
                  children: [
                    Expanded(child: _buildInfoRow(Icons.business, 'Owner', '${isotank['owner'] ?? '-'}')),
                    Expanded(child: _buildInfoRow(Icons.category, 'Product', '${isotank['product'] ?? '-'}')),
                  ],
                ),
                const SizedBox(height: 4),
                 _buildInfoRow(Icons.local_shipping, 'Capacity', '${isotank['capacity'] ?? '-'} L'),
              ],
            ),
          ),

          // Items List (Dynamic)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (_inspectionData?['items'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final items = _inspectionData!['items'] as List;
                final item = items[index];
                return _buildItemCard({
                  'key': item['key'],
                  'name': item['name'],
                }, index);
              },
            ),
          ),

          // Submit Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: _isSubmitting || (_inspectionData?['already_confirmed'] == true)
                  ? null
                  : _submitConfirmations,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0D47A1),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'SUBMIT CONFIRMATION',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
