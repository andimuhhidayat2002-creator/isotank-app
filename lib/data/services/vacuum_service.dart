import 'package:dio/dio.dart';
import '../models/vacuum_models.dart';
import 'api_service.dart';

class VacuumService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getIsotanks() async {
    try {
      // Use the already robust and tested search method from ApiService
      return await _api.searchIsotanks('');
    } catch (e) {
      rethrow;
    }
  }

  Future<VacuumSuctionEvent?> getActiveEvent(int isotankId) async {
    try {
      final response = await _api.dio.get('/vacuum/suction/$isotankId/active');
      
      // Handle Laravel wrapper { success: true, data: { ... } }
      final rawData = response.data;
      final data = (rawData is Map && rawData.containsKey('data')) ? rawData['data'] : rawData;
      
      if (data == null) return null;
      return VacuumSuctionEvent.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<VacuumSuctionEvent> startSuction(int isotankId, double prePortable, double preTemp, double startMachine) async {
    try {
      final response = await _api.dio.post('/vacuum/suction/start', data: {
        'isotank_id': isotankId,
        'pre_portable_vacuum': prePortable,
        'pre_isotank_temp': preTemp,
        'start_machine_vacuum': startMachine
      });
      
      final rawData = response.data;
      final data = (rawData is Map && rawData.containsKey('data')) ? rawData['data'] : rawData;
      
      return VacuumSuctionEvent.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> finishSuction(int eventId, double endMachine, double postPortable, double postTemp) async {
    try {
      await _api.dio.post('/vacuum/suction/$eventId/finish', data: {
        'end_machine_vacuum': endMachine,
        'post_portable_vacuum': postPortable,
        'post_isotank_temp': postTemp
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addMonitoringLog(int eventId, double vacuum, double temp, String period) async {
    try {
      await _api.dio.post('/vacuum/monitoring/add', data: {
        'suction_event_id': eventId,
        'vacuum_value': vacuum,
        'temperature': temp,
        'period': period
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getMonitoringSessions() async {
    try {
      final response = await _api.dio.get('/maintenance/vacuum/monitoring');
      final data = response.data;
      return (data is Map && data.containsKey('data')) ? data['data'] : (data is List ? data : []);
    } catch (e) {
      rethrow;
    }
  }
}
