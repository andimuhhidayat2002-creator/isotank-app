import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ReceiverService {
  final ApiService _apiService = ApiService();

  /// Get inspection details for receiver confirmation
  Future<Map<String, dynamic>> getInspectionForReceiver(int jobId) async {
    try {
      return await _apiService.getInspectionForReceiver(jobId);
    } catch (e) {
      throw Exception('Failed to load inspection: $e');
    }
  }

  /// Submit receiver confirmations with multipart form data
  Future<Map<String, dynamic>> submitConfirmations(
    int jobId,
    Map<String, Map<String, dynamic>> confirmations, {
    dynamic signatureFile,
  }) async {
    try {
      final formData = FormData();
      
      // Add signature (Mandatory per new business logic)
      if (signatureFile != null) {
          // Handle File object (Mobile)
          // We assume signatureFile is of type File (dart:io) which has a path property
          // Since we can't import dart:io here easily without breaking web if strict, 
          // we treat it as dynamic and check property.
          // For now, let's assume it's a File and use path.
          
          if (signatureFile.toString().contains("File:")) {
             // It's likely a File object
             try {
                // Determine path or bytes
                String path = (signatureFile as dynamic).path;
                 formData.files.add(MapEntry(
                  'receiver_signature',
                  await MultipartFile.fromFile(path, filename: 'receiver_signature.png'),
                ));
             } catch (e) {
               // ignore
             }
          }
      }

      // Add confirmations data
      for (final entry in confirmations.entries) {
        final itemKey = entry.key;
        final confirmation = entry.value;

        // Add decision (required)
        formData.fields.add(MapEntry('confirmations[$itemKey][decision]', confirmation['decision']!));

        // Add remark (optional)
        if (confirmation['remark'] != null && confirmation['remark'].toString().isNotEmpty) {
          formData.fields.add(MapEntry('confirmations[$itemKey][remark]', confirmation['remark']));
        }

        // Add photo (optional) - support both File path and XFile
        if (confirmation['photo'] != null) {
          final photo = confirmation['photo'];
          if (photo is String && photo.isNotEmpty && !photo.startsWith('blob:')) {
            // File path (Mobile)
            formData.files.add(MapEntry(
              'confirmations[$itemKey][photo]',
              await MultipartFile.fromFile(photo, filename: photo.split('/').last),
            ));
          } else if (photo is XFile) {
            // XFile (Web/Mobile)
            final bytes = await photo.readAsBytes();
            formData.files.add(MapEntry(
              'confirmations[$itemKey][photo]',
              MultipartFile.fromBytes(bytes, filename: photo.name),
            ));
          }
        }
      }

      return await _apiService.submitReceiverConfirmations(jobId, formData);
    } catch (e) {
      throw Exception('Failed to submit confirmations: $e');
    }
  }
}

