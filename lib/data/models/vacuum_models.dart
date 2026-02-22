class VacuumSuctionEvent {
  final int id;
  final int isotankId;
  final DateTime startTime;
  final String status;
  final double prePortableVacuum;
  final double preIsotankTemp;
  final double startMachineVacuum;
  final double? endMachineVacuum;
  final double? postPortableVacuum;
  final double? postIsotankTemp;
  final List<VacuumMonitoringLog> logs;

  VacuumSuctionEvent({
    required this.id,
    required this.isotankId,
    required this.startTime,
    required this.status,
    required this.prePortableVacuum,
    required this.preIsotankTemp,
    required this.startMachineVacuum,
    this.endMachineVacuum,
    this.postPortableVacuum,
    this.postIsotankTemp,
    this.logs = const [],
  });

  factory VacuumSuctionEvent.fromJson(Map<String, dynamic> json) {
    return VacuumSuctionEvent(
      id: json['id'],
      isotankId: json['isotank_id'] ?? 0,
      startTime: DateTime.parse(json['start_time']),
      status: json['status'],
      prePortableVacuum: (json['pre_portable_vacuum'] as num).toDouble(),
      preIsotankTemp: (json['pre_isotank_temp'] as num).toDouble(),
      startMachineVacuum: (json['start_machine_vacuum'] as num?)?.toDouble() ?? 0.0,
      endMachineVacuum: (json['end_machine_vacuum'] as num?)?.toDouble(),
      postPortableVacuum: (json['post_portable_vacuum'] as num?)?.toDouble(),
      postIsotankTemp: (json['post_isotank_temp'] as num?)?.toDouble(),
      logs: (json['logs'] as List?)?.map((l) => VacuumMonitoringLog.fromJson(l)).toList() ?? [],
    );
  }
}

class VacuumMonitoringLog {
  final int id;
  final DateTime readingAt;
  final double vacuumValue;
  final double temperature;
  final String period;

  VacuumMonitoringLog({
    required this.id,
    required this.readingAt,
    required this.vacuumValue,
    required this.temperature,
    required this.period,
  });

  factory VacuumMonitoringLog.fromJson(Map<String, dynamic> json) {
    return VacuumMonitoringLog(
      id: json['id'],
      readingAt: DateTime.parse(json['reading_at']),
      vacuumValue: (json['vacuum_value'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      period: json['period'],
    );
  }
}
