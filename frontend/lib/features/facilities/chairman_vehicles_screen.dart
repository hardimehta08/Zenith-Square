import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/facilities_api_service.dart';

class ChairmanVehiclesScreen extends StatefulWidget {
  const ChairmanVehiclesScreen({super.key});

  @override
  State<ChairmanVehiclesScreen> createState() => _ChairmanVehiclesScreenState();
}

class _ChairmanVehiclesScreenState extends State<ChairmanVehiclesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle & Parking Directory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Society Directory'),
            Tab(text: 'My Vehicles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SocietyVehiclesDirectoryTab(),
          _ChairmanPersonalVehiclesTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SOCIETY-WIDE VEHICLE DIRECTORY (GET /vehicles/?all=true)
// -------------------------------------------------------------
class _SocietyVehiclesDirectoryTab extends StatefulWidget {
  const _SocietyVehiclesDirectoryTab();

  @override
  State<_SocietyVehiclesDirectoryTab> createState() =>
      _SocietyVehiclesDirectoryTabState();
}

class _SocietyVehiclesDirectoryTabState
    extends State<_SocietyVehiclesDirectoryTab> {
  late Future<List<dynamic>> _vehiclesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', '4_wheeler', '2_wheeler'

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  void _loadDirectory() {
    setState(() {
      _vehiclesFuture = FacilitiesApiService.fetchVehicles(allSociety: true);
    });
  }

  Future<void> _handleDelete(String vehicleId, String vehicleNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deregister Vehicle'),
        content: Text(
          'Deregister vehicle "$vehicleNumber" from the society database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Deregister',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await FacilitiesApiService.deleteVehicle(vehicleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Vehicle deregistered.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadDirectory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showVehicleDetailsModal(Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VehicleDetailsSheet(
        vehicle: vehicle,
        onDeregister: () {
          Navigator.pop(ctx);
          final id = (vehicle['vehicle_id'] ?? '').toString();
          final plate = (vehicle['vehicle_number'] ?? '').toString();
          if (id.isNotEmpty) {
            _handleDelete(id, plate);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Type Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search plate (GJ01...), resident, flat, slot, phone...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.blue.shade800,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Vehicles', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      '4-Wheelers',
                      '4_wheeler',
                      icon: Icons.directions_car,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      '2-Wheelers',
                      '2_wheeler',
                      icon: Icons.two_wheeler,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _vehiclesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadDirectory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allVehicles = snapshot.data ?? [];
              final filtered = allVehicles.where((v) {
                final vType = (v['vehicle_type'] ?? '')
                    .toString()
                    .toLowerCase();
                if (_typeFilter == '4_wheeler' && !vType.contains('4'))
                  return false;
                if (_typeFilter == '2_wheeler' && !vType.contains('2'))
                  return false;

                if (_searchQuery.isEmpty) return true;
                final plate = (v['vehicle_number'] ?? '')
                    .toString()
                    .toLowerCase();
                final resident = (v['resident_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final flat = (v['flat_number'] ?? '').toString().toLowerCase();
                final block = (v['block_name'] ?? '').toString().toLowerCase();
                final slot =
                    ((v['vehicle_allotment_number'] ?? v['parking_slot']) ?? '')
                        .toString()
                        .toLowerCase();
                final phone = (v['resident_phone'] ?? '')
                    .toString()
                    .toLowerCase();

                return plate.contains(_searchQuery) ||
                    resident.contains(_searchQuery) ||
                    flat.contains(_searchQuery) ||
                    block.contains(_searchQuery) ||
                    slot.contains(_searchQuery) ||
                    phone.contains(_searchQuery);
              }).toList();

              final fourWheelerCount = allVehicles
                  .where(
                    (v) => (v['vehicle_type'] ?? '').toString().contains('4'),
                  )
                  .length;
              final twoWheelerCount = allVehicles
                  .where(
                    (v) => (v['vehicle_type'] ?? '').toString().contains('2'),
                  )
                  .length;

              return Column(
                children: [
                  // Summary Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filtered.length} of ${allVehicles.length} Resident Vehicles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                '$fourWheelerCount Cars',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: Text(
                                '$twoWheelerCount Bikes',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: filtered.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () async => _loadDirectory(),
                            child: ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.15,
                                ),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.directions_car_outlined,
                                        size: 54,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No resident vehicles match "$_searchQuery"'
                                            : 'No resident vehicles registered yet.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadDirectory(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12.0),
                              itemCount: filtered.length,
                              separatorBuilder: (ctx, i) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final v = filtered[i];
                                final is4W = (v['vehicle_type'] ?? '')
                                    .toString()
                                    .contains('4');
                                final plateStr =
                                    (v['vehicle_number'] ?? 'GJ01AB0000')
                                        .toString()
                                        .toUpperCase();
                                final residentName =
                                    v['resident_name'] ?? 'Society Resident';
                                final slot =
                                    ((v['vehicle_allotment_number'] ??
                                                v['parking_slot']) ??
                                            '')
                                        .toString()
                                        .trim();
                                final flat = (v['flat_number'] ?? '')
                                    .toString()
                                    .trim();
                                final block = (v['block_name'] ?? 'Block A')
                                    .toString()
                                    .trim();
                                final phone = (v['resident_phone'] ?? '')
                                    .toString()
                                    .trim();

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showVehicleDetailsModal(v),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildIndLicensePlate(plateStr),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: is4W
                                                          ? Colors.blue.shade50
                                                          : Colors.teal.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: is4W
                                                            ? Colors
                                                                  .blue
                                                                  .shade200
                                                            : Colors
                                                                  .teal
                                                                  .shade200,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          is4W
                                                              ? Icons
                                                                    .directions_car
                                                              : Icons
                                                                    .two_wheeler,
                                                          size: 15,
                                                          color: is4W
                                                              ? Colors
                                                                    .blue
                                                                    .shade800
                                                              : Colors
                                                                    .teal
                                                                    .shade800,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          is4W
                                                              ? '4-Wheeler'
                                                              : '2-Wheeler',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: is4W
                                                                ? Colors
                                                                      .blue
                                                                      .shade900
                                                                : Colors
                                                                      .teal
                                                                      .shade900,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20,
                                                    ),
                                                    tooltip:
                                                        'Deregister Vehicle',
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    onPressed: () =>
                                                        _handleDelete(
                                                          v['vehicle_id']
                                                              .toString(),
                                                          plateStr,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor:
                                                    Colors.blue.shade50,
                                                child: Icon(
                                                  Icons.person,
                                                  size: 18,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      residentName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Flat $flat • $block${phone.isNotEmpty ? " • 📞 $phone" : ""}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color:
                                                        Colors.amber.shade300,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.local_parking,
                                                      size: 14,
                                                      color:
                                                          Colors.amber.shade900,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      slot.isNotEmpty
                                                          ? 'Parking Slot: $slot'
                                                          : 'Slot Allotted',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .amber
                                                            .shade900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'View Details',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.blue.shade800,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    size: 16,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, {IconData? icon}) {
    final isSelected = _typeFilter == value;
    return ChoiceChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            )
          : null,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.blue.shade800,
      backgroundColor: Colors.grey.shade100,
      onSelected: (val) {
        if (val) setState(() => _typeFilter = value);
      },
    );
  }
}

// -------------------------------------------------------------
// REUSABLE RESIDENT VEHICLE DETAILS BOTTOM SHEET MODAL
// -------------------------------------------------------------
class _VehicleDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback? onDeregister;

  const _VehicleDetailsSheet({required this.vehicle, this.onDeregister});

  @override
  Widget build(BuildContext context) {
    final is4W = (vehicle['vehicle_type'] ?? '').toString().contains('4');
    final plateStr = (vehicle['vehicle_number'] ?? 'GJ01AB0000')
        .toString()
        .toUpperCase();
    final residentName = vehicle['resident_name'] ?? 'Society Resident';
    final slot =
        ((vehicle['vehicle_allotment_number'] ?? vehicle['parking_slot']) ?? '')
            .toString()
            .trim();
    final flat = (vehicle['flat_number'] ?? '').toString().trim();
    final block = (vehicle['block_name'] ?? 'Block A').toString().trim();
    final phone = (vehicle['resident_phone'] ?? '').toString().trim();
    final socName =
        (vehicle['society_name'] != null &&
            vehicle['society_name'].toString().isNotEmpty)
        ? vehicle['society_name'].toString()
        : 'Zenith Square';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: is4W ? Colors.blue.shade50 : Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        is4W ? Icons.directions_car : Icons.two_wheeler,
                        color: is4W
                            ? Colors.blue.shade800
                            : Colors.teal.shade800,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resident Vehicle Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Society Pass: #${vehicle['vehicle_id'] ?? "001"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: _buildIndLicensePlate(
                plateStr,
                fontSize: 22,
                isLarge: true,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: plateStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle plate "$plateStr" copied!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 14),
                label: const Text(
                  'Copy License Plate Number',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.green.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified Society Resident Vehicle • Authorized Entry',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionHeader('Vehicle & Parking Allocation'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: is4W ? Icons.directions_car : Icons.two_wheeler,
                    label: 'Vehicle Category',
                    value: is4W
                        ? '4-Wheeler (Car / SUV)'
                        : '2-Wheeler (Motorcycle / Scooter)',
                    isBold: true,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.local_parking,
                    label: 'Designated Parking Slot',
                    value: slot.isNotEmpty ? 'Slot $slot' : 'Allotted Bay',
                    valueColor: Colors.amber.shade900,
                    isBold: true,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.security,
                    label: 'Gate Clearance',
                    value: 'Auto-Clearance for Society Gates',
                    valueColor: Colors.green.shade800,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionHeader('Resident Owner Details'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withAlpha(128),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.person_pin,
                    label: 'Owner Full Name',
                    value: residentName,
                    isBold: true,
                    valueColor: Colors.blue.shade900,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.apartment,
                    label: 'Residence Flat',
                    value: 'Flat $flat • $block ($socName)',
                    isBold: true,
                  ),
                  if (phone.isNotEmpty) ...[
                    const Divider(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.blue.shade800,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Owner Phone: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Resident phone copied to clipboard',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Text(
                              'Copy Phone',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onDeregister != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onDeregister,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Deregister Vehicle',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.3,
      ),
    ),
  );
}

Widget _buildDetailRow({
  required IconData icon,
  required String label,
  required String value,
  Color? valueColor,
  bool isBold = false,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade700),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ),
    ],
  );
}

Widget _buildIndLicensePlate(
  String plateNumber, {
  double fontSize = 15,
  bool isLarge = false,
}) {
  final cleanPlate = plateNumber.replaceAll(' ', '').toUpperCase();
  String displayPlate = cleanPlate;
  if (cleanPlate.length >= 8) {
    displayPlate =
        '${cleanPlate.substring(0, 2)} ${cleanPlate.substring(2, 4)} ${cleanPlate.substring(4, cleanPlate.length - 4)} ${cleanPlate.substring(cleanPlate.length - 4)}';
  }

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isLarge ? 12 : 8,
      vertical: isLarge ? 6 : 4,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.black, width: isLarge ? 2.0 : 1.4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF003399),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'IND',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(width: isLarge ? 10 : 8),
        Text(
          displayPlate,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  );
}

// -------------------------------------------------------------
// TAB 2: CHAIRMAN PERSONAL UNIT VEHICLES (GET /vehicles/)
// -------------------------------------------------------------
class _ChairmanPersonalVehiclesTab extends StatefulWidget {
  const _ChairmanPersonalVehiclesTab();

  @override
  State<_ChairmanPersonalVehiclesTab> createState() =>
      _ChairmanPersonalVehiclesTabState();
}

class _ChairmanPersonalVehiclesTabState
    extends State<_ChairmanPersonalVehiclesTab> {
  late Future<List<dynamic>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    setState(() {
      _vehiclesFuture = FacilitiesApiService.fetchVehicles(allSociety: false);
    });
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  void _openAddVehicleSheet() {
    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController();
    final allotmentController = TextEditingController();
    String selectedType = '4-Wheeler';
    bool isSubmitting = false;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register Unit Vehicle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        numberController.dispose();
                        allotmentController.dispose();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('Vehicle Plate Number', isRequired: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: numberController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 12,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'e.g. GJ01AB1234',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim().toUpperCase() ?? '';
                    if (val.isEmpty) return 'Please enter plate number';
                    if (val.length < 6) {
                      return 'Invalid vehicle registration number (min 6 chars)';
                    }
                    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(val)) {
                      return 'Only letters and numbers allowed (no spaces or symbols)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('Vehicle Type', isRequired: true),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '2-Wheeler',
                      child: Text('2-Wheeler (Bike/Scooter)'),
                    ),
                    DropdownMenuItem(
                      value: '4-Wheeler',
                      child: Text('4-Wheeler (Car/SUV)'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                _buildFieldLabel(
                  'Parking Slot / Sticker Tag',
                  isRequired: true,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: allotmentController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    hintText: 'e.g. P-101, B-SLOT-04',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Enter parking slot or sticker tag';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (sheetError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Colors.red.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sheetError!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() {
                            isSubmitting = true;
                            sheetError = null;
                          });
                          try {
                            final res =
                                await FacilitiesApiService.registerVehicle(
                                  vehicleNumber: numberController.text
                                      .trim()
                                      .toUpperCase(),
                                  vehicleType: selectedType,
                                  allotmentNumber: allotmentController.text
                                      .trim(),
                                );
                            if (mounted) {
                              numberController.dispose();
                              allotmentController.dispose();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Vehicle registered!',
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                              _loadVehicles();
                            }
                          } catch (e) {
                            setModalState(() {
                              isSubmitting = false;
                              sheetError = e.toString().replaceAll(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueGrey,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Vehicle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVehicleSheet,
        backgroundColor: Colors.blueGrey,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadVehicles,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No personal vehicles registered.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadVehicles(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: vehicles.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final v = vehicles[i];
                final isTwoWheeler = (v['vehicle_type'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains('2');

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey.shade50,
                      child: Icon(
                        isTwoWheeler ? Icons.two_wheeler : Icons.directions_car,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                    title: Text(
                      v['vehicle_number'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Type: ${v['vehicle_type']}\nParking Slot: ${v['vehicle_allotment_number']}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remove',
                      onPressed: () async {
                        await FacilitiesApiService.deleteVehicle(
                          v['vehicle_id'],
                        );
                        _loadVehicles();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
