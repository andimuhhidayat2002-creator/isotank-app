import 'package:flutter/material.dart';
import '../../../data/models/vacuum_models.dart';
import '../../../data/services/vacuum_service.dart';
import 'vacuum_monitoring_dashboard.dart';

class VacuumSuctionScreen extends StatefulWidget {
  const VacuumSuctionScreen({super.key});

  @override
  State<VacuumSuctionScreen> createState() => _VacuumSuctionScreenState();
}

class _VacuumSuctionScreenState extends State<VacuumSuctionScreen> {
  final VacuumService _vacuumService = VacuumService();
  
  List<dynamic> _isotanks = [];
  int? _selectedTankId;
  VacuumSuctionEvent? _activeEvent;
  bool _isLoading = false;

  // Controllers
  final _prePortableCtrl = TextEditingController();
  final _preTempCtrl = TextEditingController();
  final _startMachineCtrl = TextEditingController();
  
  final _endMachineCtrl = TextEditingController();
  final _postPortableCtrl = TextEditingController();
  final _postTempCtrl = TextEditingController();

  final _monitorVacuumCtrl = TextEditingController();
  final _monitorTempCtrl = TextEditingController();
  String _monitorPeriod = 'Morning';
  String _prePortableUnit = 'mtorr';
  String _postPortableUnit = 'mtorr';
  String _monitorVacuumUnit = 'mtorr';

  @override
  void initState() {
    super.initState();
    _loadIsotanks();
  }

  Future<void> _loadIsotanks() async {
    try {
      final tanks = await _vacuumService.getIsotanks();
      setState(() {
        _isotanks = tanks;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading tanks: $e')));
    }
  }

  Future<void> _checkActiveEvent(int tankId) async {
    setState(() => _isLoading = true);
    try {
      final event = await _vacuumService.getActiveEvent(tankId);
      setState(() {
        _activeEvent = event;
      });
    } catch (e) {
      // It might return 404 or null if no event, handled in service?
      // Service returns null if 404-like logic is handled, or empty.
      // My service returns null if body is empty.
       setState(() {
        _activeEvent = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startSuction() async {
    if (_selectedTankId == null) return;
    setState(() => _isLoading = true);
    try {
      await _vacuumService.startSuction(
        _selectedTankId!, 
        _prePortableCtrl.text,
        _prePortableUnit,
        double.parse(_preTempCtrl.text),
        _startMachineCtrl.text
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suction Started!')));
      _checkActiveEvent(_selectedTankId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finishSuction() async {
    if (_activeEvent == null) return;
    setState(() => _isLoading = true);
    try {
      await _vacuumService.finishSuction(
        _activeEvent!.id,
        _endMachineCtrl.text,
        _postPortableCtrl.text,
        _postPortableUnit,
        double.parse(_postTempCtrl.text)
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suction Finished! Info logged.')));
      _checkActiveEvent(_selectedTankId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addLog() async {
    if (_activeEvent == null) return;
    setState(() => _isLoading = true);
    try {
      await _vacuumService.addMonitoringLog(
        _activeEvent!.id,
        _monitorVacuumCtrl.text,
        _monitorVacuumUnit,
        double.parse(_monitorTempCtrl.text),
        _monitorPeriod
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log Added!')));
      _checkActiveEvent(_selectedTankId!);
      // Clear inputs
      _monitorVacuumCtrl.clear();
      _monitorTempCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeMonitoring() async {
    if (_activeEvent == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Early?'),
        content: const Text('This will finish the 5-day monitoring phase immediately and save the latest data into the vacuum history logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Complete')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _vacuumService.completeMonitoring(_activeEvent!.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monitoring Phase Completed!')));
      _checkActiveEvent(_selectedTankId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _showDashboard = true;

  @override
  Widget build(BuildContext context) {
    if (_showDashboard) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monitoring Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showDashboard = false),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                )
              ],
            ),
          ),
          Expanded(
            child: VacuumMonitoringDashboard(
              onSelectIsotank: (id) {
                setState(() {
                  _selectedTankId = id;
                  _showDashboard = false;
                });
                _checkActiveEvent(id);
              },
            ),
          ),
        ],
      );
    }

    // If no tank selected, show list or dropdown
    // For simplicity, let's use a Dropdown at the top
    return WillPopScope(
      onWillPop: () async {
        setState(() => _showDashboard = true);
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _showDashboard = true), 
                  icon: const Icon(Icons.arrow_back)
                ),
                const Text('New Vacuum Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Select Isotank', border: OutlineInputBorder()),
              value: _selectedTankId,
              items: _isotanks.map((t) {
                return DropdownMenuItem<int>(
                  value: t['id'],
                  child: Text(t['iso_number'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTankId = val);
                  _checkActiveEvent(val);
                }
              },
            ),
            const SizedBox(height: 20),
  
            if (_isLoading) const Center(child: CircularProgressIndicator()),
  
            if (!_isLoading && _selectedTankId != null && _activeEvent == null)
              _buildStartForm(),
  
            if (!_isLoading && _activeEvent != null && _activeEvent!.status == 'ongoing')
              _buildFinishForm(),
  
            if (!_isLoading && _activeEvent != null && _activeEvent!.status == 'monitoring')
              _buildMonitoringView(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Start Suction Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: TextField(controller: _prePortableCtrl, decoration: const InputDecoration(labelText: 'Portable Vacuum'), keyboardType: TextInputType.text)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _prePortableUnit,
                  items: const [
                    DropdownMenuItem(value: 'mtorr', child: Text('mTorr')),
                    DropdownMenuItem(value: 'scientific', child: Text('Scientific Torr')),
                  ],
                  onChanged: (v) => setState(() => _prePortableUnit = v!),
                )
              ],
            ),
            TextField(controller: _preTempCtrl, decoration: const InputDecoration(labelText: 'Isotank Temp (°C)'), keyboardType: TextInputType.number),
            TextField(controller: _startMachineCtrl, decoration: const InputDecoration(labelText: 'Machine Vacuum Start (Scientific Torr)'), keyboardType: TextInputType.text),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startSuction,
              child: const Text('Start Suction'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFinishForm() {
    return Card(
      color: Colors.yellow[50],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Suction In Progress (Started: ${_activeEvent!.startTime})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _endMachineCtrl, decoration: const InputDecoration(labelText: 'Machine Vacuum End (Scientific Torr)'), keyboardType: TextInputType.text),
            Row(
              children: [
                Expanded(child: TextField(controller: _postPortableCtrl, decoration: const InputDecoration(labelText: 'Portable Vacuum After'), keyboardType: TextInputType.text)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _postPortableUnit,
                  items: const [
                    DropdownMenuItem(value: 'mtorr', child: Text('mTorr')),
                    DropdownMenuItem(value: 'scientific', child: Text('Scientific Torr')),
                  ],
                  onChanged: (v) => setState(() => _postPortableUnit = v!),
                )
              ],
            ),
            TextField(controller: _postTempCtrl, decoration: const InputDecoration(labelText: 'Isotank Temp After (°C)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _finishSuction,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Finish & Start Monitoring'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringView() {
    return Column(
      children: [
        Card(
          color: Colors.purple[50],
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Monitoring Phase (3 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _monitorPeriod,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: ['Morning', 'Evening', 'Extra Day'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setState(() => _monitorPeriod = val!),
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _monitorVacuumCtrl, decoration: const InputDecoration(labelText: 'Vacuum Value'), keyboardType: TextInputType.text)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _monitorVacuumUnit,
                      items: const [
                        DropdownMenuItem(value: 'mtorr', child: Text('mTorr')),
                        DropdownMenuItem(value: 'scientific', child: Text('Scientific Torr')),
                      ],
                      onChanged: (v) => setState(() => _monitorVacuumUnit = v!),
                    )
                  ],
                ),
                TextField(controller: _monitorTempCtrl, decoration: const InputDecoration(labelText: 'Temperature (°C)'), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addLog,
                        child: const Text('Add Log'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _completeMonitoring,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        child: const Text('Complete Early'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Logged History', style: TextStyle(fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activeEvent!.logs.length,
          itemBuilder: (ctx, i) {
            final log = _activeEvent!.logs[i];
            return ListTile(
              title: Text('${log.period} - ${log.vacuumValue} mTorr'),
              subtitle: Text('Temp: ${log.temperature}°C'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
            );
          },
        )
      ],
    );
  }
}
