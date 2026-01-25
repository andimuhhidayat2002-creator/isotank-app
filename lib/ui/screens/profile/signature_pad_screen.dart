import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../logic/providers/auth_provider.dart';

class SignaturePadScreen extends StatefulWidget {
  final Function(File) onSaved;

  const SignaturePadScreen({super.key, required this.onSaved});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign before saving')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Uint8List? data = await _controller.toPngBytes();
      if (data == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(data);

      widget.onSaved(file);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving signature: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Your Signature'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _controller.clear(),
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _handleSave,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Signature(
                      controller: _controller,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: const Text(
                    'Draw your signature above. This will be used for official inspection reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }
}
