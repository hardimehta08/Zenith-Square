import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/security_api_service.dart';

class ChairmanSecurityScreen extends StatefulWidget {
  const ChairmanSecurityScreen({super.key});

  @override
  State<ChairmanSecurityScreen> createState() => _ChairmanSecurityScreenState();
}

class _ChairmanSecurityScreenState extends State<ChairmanSecurityScreen>
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
        title: const Text('Security & SOS Desk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.crisis_alert, size: 18),
              text: 'Active Alerts & SOS',
            ),
            Tab(
              icon: Icon(Icons.badge_outlined, size: 18),
              text: 'Visitor Details & Logs',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ChairmanAlertsTab(), _ChairmanVisitorAuditTab()],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: ACTIVE ALERTS, SOS BROADCAST & DISMISSAL
// -------------------------------------------------------------
class _ChairmanAlertsTab extends StatefulWidget {
  const _ChairmanAlertsTab();

  @override
  State<_ChairmanAlertsTab> createState() => _ChairmanAlertsTabState();
}

class _ChairmanAlertsTabState extends State<_ChairmanAlertsTab> {
  late Future<List<dynamic>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    if (!mounted) return;
    setState(() {
      _alertsFuture = SecurityApiService.fetchActiveSecurityAlerts();
    });
  }

  Future<void> _handleDismissAlert(String alertId, String alertType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency Alert'),
        content: Text(
          'Mark "$alertType" as resolved? This will clear the alert across the society.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Mark Resolved',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await SecurityApiService.dismissSecurityAlert(alertId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Alert resolved.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadAlerts();
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

  Future<void> _showTriggerSosModal() async {
    final formKey = GlobalKey<FormState>();
    String selectedType = 'Medical Emergency';
    final descController = TextEditingController();
    bool isSubmitting = false;
    String? sheetError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
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
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Broadcast SOS Alert',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This will immediately alert gate security and society members.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Emergency Type', isRequired: true),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Medical Emergency',
                        child: Text('Medical Emergency'),
                      ),
                      DropdownMenuItem(
                        value: 'Fire Emergency',
                        child: Text('Fire Hazard'),
                      ),
                      DropdownMenuItem(
                        value: 'Lift Stuck',
                        child: Text('Lift / Elevator Stuck'),
                      ),
                      DropdownMenuItem(
                        value: 'Theft / Intruder',
                        child: Text('Theft / Suspicious Activity'),
                      ),
                      DropdownMenuItem(
                        value: 'Other Emergency',
                        child: Text('Other Emergency'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    'Location / Emergency Details',
                    isRequired: true,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g., Main pump house water burst, resident trapped',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) {
                        return 'Please describe the emergency location and issue';
                      }
                      if (val.length < 5) {
                        return 'Details must be at least 5 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

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
                                  await SecurityApiService.triggerEmergencyAlert(
                                    alertType: selectedType,
                                    description: descController.text.trim(),
                                  );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Alert broadcasted!',
                                    ),
                                    backgroundColor: Colors.red.shade800,
                                  ),
                                );
                                _loadAlerts();
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
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                            'BROADCAST SOS NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    descController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Material(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _showTriggerSosModal,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crisis_alert, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'TRIGGER EMERGENCY SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _alertsFuture,
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
                        onPressed: _loadAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No active emergency alerts in your society.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All society gates and facilities operating normally.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadAlerts(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  itemCount: alerts.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final a = alerts[i];
                    final dateStr = a['created_at'] != null
                        ? a['created_at']
                              .toString()
                              .substring(0, 16)
                              .replaceAll('T', ' ')
                        : '';

                    return Card(
                      elevation: 0,
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  a['alert_type'] ?? 'Emergency',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a['description'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 13,
                              ),
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'By: ${a['triggered_by_name'] ?? 'Resident'} (${a['triggered_by_phone'] ?? ''})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleDismissAlert(
                                  a['alert_id'],
                                  a['alert_type'] ?? 'Alert',
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('Resolve Alert'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 2: SOCIETY-WIDE GATE VISITOR LOGS AUDIT & DETAILS
// -------------------------------------------------------------
class _ChairmanVisitorAuditTab extends StatefulWidget {
  const _ChairmanVisitorAuditTab();

  @override
  State<_ChairmanVisitorAuditTab> createState() =>
      _ChairmanVisitorAuditTabState();
}

class _ChairmanVisitorAuditTabState extends State<_ChairmanVisitorAuditTab> {
  late Future<List<dynamic>> _visitorsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  void _loadVisitors() {
    if (!mounted) return;
    setState(() {
      _visitorsFuture = SecurityApiService.fetchVisitorLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleMarkExit(int logId, String visitorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            const Text('Log Visitor Exit'),
          ],
        ),
        content: Text(
          'Record exit timestamp for "$visitorName"? This will mark them as exited the society gate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await SecurityApiService.logVisitorExit(logId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message'] ?? 'Visitor exit timestamp recorded.',
              ),
              backgroundColor: Colors.blue.shade800,
            ),
          );
          _loadVisitors();
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
  }

  void _showVisitorDetailsModal(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VisitorDetailsSheet(
        log: log,
        onMarkExit: () {
          Navigator.pop(ctx);
          final logId = log['log_id'] ?? log['logs_id'];
          if (logId != null) {
            _handleMarkExit(logId, log['visitor_name'] ?? 'Visitor');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search visitor, phone, flat (A-101), host resident...',
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
                    _buildFilterChip('All Logs', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Inside Now',
                      'inside',
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Exited',
                      'exited',
                      icon: Icons.check_circle_outline,
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
            future: _visitorsFuture,
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
                        onPressed: _loadVisitors,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allLogs = snapshot.data ?? [];
              final filtered = allLogs.where((log) {
                final isInside = (log['exit_time'] == null);
                if (_statusFilter == 'inside' && !isInside) return false;
                if (_statusFilter == 'exited' && isInside) return false;

                if (_searchQuery.isEmpty) return true;
                final name = (log['visitor_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final phone = (log['visitor_phone'] ?? '')
                    .toString()
                    .toLowerCase();
                final flat = (log['flat_number'] ?? '')
                    .toString()
                    .toLowerCase();
                final block = (log['block_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final purpose = (log['purpose'] ?? '').toString().toLowerCase();
                final resident = (log['resident_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final guard = (log['recorded_by_name'] ?? '')
                    .toString()
                    .toLowerCase();

                return name.contains(_searchQuery) ||
                    phone.contains(_searchQuery) ||
                    flat.contains(_searchQuery) ||
                    block.contains(_searchQuery) ||
                    purpose.contains(_searchQuery) ||
                    resident.contains(_searchQuery) ||
                    guard.contains(_searchQuery);
              }).toList();

              final insideCount = allLogs
                  .where((l) => l['exit_time'] == null)
                  .length;
              final exitedCount = allLogs
                  .where((l) => l['exit_time'] != null)
                  .length;

              return Column(
                children: [
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
                          'Showing ${filtered.length} of ${allLogs.length} Records',
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
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                              ),
                              child: Text(
                                '$insideCount Inside',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
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
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$exitedCount Exited',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
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
                            onRefresh: () async => _loadVisitors(),
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
                                        Icons.badge_outlined,
                                        size: 54,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No visitor records match "$_searchQuery"'
                                            : 'No visitors recorded for this filter.',
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
                            onRefresh: () async => _loadVisitors(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12.0),
                              itemCount: filtered.length,
                              separatorBuilder: (ctx, i) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final log = filtered[i];
                                final hasExited = log['exit_time'] != null;
                                final entryTime = log['entry_time'] != null
                                    ? log['entry_time'].toString().substring(
                                        11,
                                        16,
                                      )
                                    : '--:--';
                                final entryDate = log['entry_time'] != null
                                    ? log['entry_time'].toString().substring(
                                        0,
                                        10,
                                      )
                                    : '';
                                final exitTime = hasExited
                                    ? log['exit_time'].toString().substring(
                                        11,
                                        16,
                                      )
                                    : null;
                                final flatStr =
                                    'Flat ${log['flat_number'] ?? ''} (${log['block_name'] ?? 'Block A'})';
                                final hostResident =
                                    (log['resident_name'] ?? '')
                                        .toString()
                                        .trim();

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: hasExited
                                          ? Colors.grey.shade300
                                          : Colors.green.shade400,
                                      width: hasExited ? 1.0 : 1.4,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showVisitorDetailsModal(log),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: hasExited
                                                    ? Colors.grey.shade200
                                                    : Colors.green.shade100,
                                                child: Icon(
                                                  _getPurposeIcon(
                                                    log['purpose'] ?? '',
                                                  ),
                                                  color: hasExited
                                                      ? Colors.grey.shade700
                                                      : Colors.green.shade800,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      log['visitor_name'] ??
                                                          'Visitor',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '📞 ${log['visitor_phone'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: hasExited
                                                      ? Colors.grey.shade100
                                                      : Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: hasExited
                                                        ? Colors.grey.shade300
                                                        : Colors.green.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  hasExited
                                                      ? 'EXITED'
                                                      : 'INSIDE',
                                                  style: TextStyle(
                                                    color: hasExited
                                                        ? Colors.grey.shade700
                                                        : Colors.green.shade800,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.blue.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.apartment,
                                                      size: 14,
                                                      color:
                                                          Colors.blue.shade800,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      flatStr,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue
                                                            .shade900,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (hostResident.isNotEmpty)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.purple.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors
                                                          .purple
                                                          .shade200,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size: 13,
                                                        color: Colors
                                                            .purple
                                                            .shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Host: $hostResident',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .purple
                                                              .shade800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                                                        Colors.amber.shade200,
                                                  ),
                                                ),
                                                child: Text(
                                                  log['purpose'] ?? 'General',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        Colors.amber.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'In: $entryDate at $entryTime',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                    if (hasExited)
                                                      Text(
                                                        'Out: $exitTime',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .blueGrey
                                                              .shade600,
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
    final isSelected = _statusFilter == value;
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
        if (val) setState(() => _statusFilter = value);
      },
    );
  }
}

// -------------------------------------------------------------
// REUSABLE VISITOR DETAILS BOTTOM SHEET MODAL
// -------------------------------------------------------------
class _VisitorDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onMarkExit;

  const _VisitorDetailsSheet({required this.log, required this.onMarkExit});

  @override
  Widget build(BuildContext context) {
    final hasExited = log['exit_time'] != null;
    final entryStr = log['entry_time'] != null
        ? log['entry_time'].toString().substring(0, 16).replaceAll('T', ' ')
        : '--';
    final exitStr = log['exit_time'] != null
        ? log['exit_time'].toString().substring(0, 16).replaceAll('T', ' ')
        : 'Still Inside Premises';
    final socName =
        (log['society_name'] != null &&
            log['society_name'].toString().isNotEmpty)
        ? log['society_name'].toString()
        : 'Zenith Square';
    final flatStr =
        'Flat ${log['flat_number'] ?? ''} - ${log['block_name'] ?? 'Block A'}';
    final residentName = (log['resident_name'] ?? '').toString().trim();
    final residentPhone = (log['resident_phone'] ?? '').toString().trim();
    final visitorPhone = (log['visitor_phone'] ?? '').toString().trim();
    final duration = _calculateStayDuration(
      log['entry_time'],
      log['exit_time'],
    );

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
                        color: hasExited
                            ? Colors.grey.shade100
                            : Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPurposeIcon(log['purpose'] ?? ''),
                        color: hasExited
                            ? Colors.grey.shade700
                            : Colors.green.shade800,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visitor Pass & Gate Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Pass ID: #${log['log_id'] ?? log['logs_id'] ?? "001"}',
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasExited
                    ? Colors.grey.shade50
                    : Colors.green.shade50.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasExited
                      ? Colors.grey.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: hasExited
                        ? Colors.grey.shade200
                        : Colors.green.shade100,
                    child: Icon(
                      Icons.person,
                      color: hasExited
                          ? Colors.grey.shade700
                          : Colors.green.shade800,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['visitor_name'] ?? 'Visitor Name',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              visitorPhone.isNotEmpty
                                  ? visitorPhone
                                  : 'No contact provided',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (visitorPhone.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: visitorPhone),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Visitor phone copied to clipboard',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: const Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasExited
                          ? Colors.grey.shade200
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasExited ? 'EXITED' : 'INSIDE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasExited
                            ? Colors.grey.shade800
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildSectionHeader('Destination & Host Resident'),
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
                    icon: Icons.apartment,
                    label: 'Destination Unit',
                    value: '$flatStr ($socName)',
                    valueColor: Colors.blue.shade900,
                    isBold: true,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Host Resident',
                    value: residentName.isNotEmpty
                        ? residentName
                        : 'Occupant of Flat',
                    isBold: true,
                  ),
                  if (residentPhone.isNotEmpty) ...[
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
                          'Host Contact: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          residentPhone,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: residentPhone),
                            );
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
            const SizedBox(height: 14),
            _buildSectionHeader('Gate Timeline & Purpose'),
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
                    icon: Icons.info_outline,
                    label: 'Visit Purpose',
                    value: log['purpose'] ?? 'General Visit',
                    isBold: true,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.login,
                    label: 'Entry Timestamp',
                    value: entryStr,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.logout,
                    label: 'Exit Timestamp',
                    value: exitStr,
                    valueColor: hasExited
                        ? Colors.black87
                        : Colors.green.shade800,
                  ),
                  const Divider(height: 14),
                  _buildDetailRow(
                    icon: Icons.timelapse,
                    label: 'Stay Duration',
                    value: duration,
                    isBold: true,
                    valueColor: Colors.purple.shade900,
                  ),
                  if (log['recorded_by_name'] != null) ...[
                    const Divider(height: 14),
                    _buildDetailRow(
                      icon: Icons.security,
                      label: 'Logged By Guard',
                      value: log['recorded_by_name'].toString(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!hasExited)
              ElevatedButton.icon(
                onPressed: onMarkExit,
                icon: const Icon(Icons.exit_to_app, size: 18),
                label: const Text(
                  'Record Gate Exit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
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

IconData _getPurposeIcon(String purpose) {
  final p = purpose.toLowerCase();
  if (p.contains('delivery') || p.contains('food') || p.contains('parcel')) {
    return Icons.delivery_dining;
  }
  if (p.contains('cab') || p.contains('taxi')) {
    return Icons.local_taxi;
  }
  if (p.contains('maintenance') || p.contains('repair')) {
    return Icons.build;
  }
  if (p.contains('maid') || p.contains('staff') || p.contains('help')) {
    return Icons.cleaning_services;
  }
  if (p.contains('doctor') || p.contains('medical')) {
    return Icons.local_hospital;
  }
  if (p.contains('courier')) {
    return Icons.local_post_office;
  }
  return Icons.person_pin;
}

String _calculateStayDuration(dynamic entryRaw, dynamic exitRaw) {
  if (entryRaw == null) return '--';
  final entry = DateTime.tryParse(entryRaw.toString());
  if (entry == null) return '--';
  final exit = exitRaw != null
      ? DateTime.tryParse(exitRaw.toString())
      : DateTime.now();
  if (exit == null) return '--';

  final diff = exit.difference(entry);
  if (diff.isNegative) return '0 min';

  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;

  if (hours == 0) {
    return '$minutes mins${exitRaw == null ? " (active)" : ""}';
  } else {
    return '$hours hr $minutes mins${exitRaw == null ? " (active)" : ""}';
  }
}
