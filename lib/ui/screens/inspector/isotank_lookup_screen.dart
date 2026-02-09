import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class IsotankLookupScreen extends StatefulWidget {
  const IsotankLookupScreen({super.key});

  @override
  State<IsotankLookupScreen> createState() => _IsotankLookupScreenState();
}

class _IsotankLookupScreenState extends State<IsotankLookupScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _apiService.searchIsotanks(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isotank Lookup'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Isotank Number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          
          // Search Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('SEARCH'),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(
                        child: Text(
                          'Enter isotank number to search',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'No isotanks found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final isotank = _searchResults[index];
                              return _IsotankCard(isotank: isotank);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _IsotankCard extends StatelessWidget {
  final Map<String, dynamic> isotank;

  const _IsotankCard({required this.isotank});

  @override
  Widget build(BuildContext context) {
    final status = isotank['filling_status'] ?? 'Unknown';
    final category = isotank['tank_category'] ?? 'T75';
    final location = isotank['current_location'] ?? 'Not Specified';
    
    Color statusColor = Colors.grey;
    if (status.toLowerCase().contains('empty')) {
      statusColor = Colors.green;
    } else if (status.toLowerCase().contains('filled')) {
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    isotank['isotank_number'] ?? 'N/A',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Details
            _DetailRow(label: 'Category', value: category),
            _DetailRow(label: 'Location', value: location),
            _DetailRow(label: 'Current Cargo', value: isotank['current_cargo'] ?? '-'),
            _DetailRow(label: 'Owner', value: isotank['owner'] ?? '-'),
            
            if (isotank['last_inspection_date'] != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Last Inspection',
                value: isotank['last_inspection_date'],
                valueColor: Colors.blue,
              ),
            ],
            
            if (isotank['vacuum_check_datetime'] != null) ...[
              _DetailRow(
                label: 'Vacuum Check',
                value: isotank['vacuum_check_datetime'],
                valueColor: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
