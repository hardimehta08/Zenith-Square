import 'package:flutter/material.dart';
import '../../data/datasource/finance_api_service.dart';
import 'widgets/financial_document_helper.dart';

class BlockSecretaryFinanceScreen extends StatefulWidget {
  const BlockSecretaryFinanceScreen({super.key});

  @override
  State<BlockSecretaryFinanceScreen> createState() =>
      _BlockSecretaryFinanceScreenState();
}

class _BlockSecretaryFinanceScreenState
    extends State<BlockSecretaryFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Block Finance & Dues'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Unit Due'),
            Tab(text: 'Block Dues Status'),
            Tab(text: 'Payment Receipts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PersonalUnitDueTab(),
          _BlockDuesStatusTab(),
          _BlockSecretaryReceiptsTab(),
        ],
      ),
    );
  }
}

// TAB 1: PERSONAL UNIT DUE
class _PersonalUnitDueTab extends StatefulWidget {
  const _PersonalUnitDueTab();

  @override
  State<_PersonalUnitDueTab> createState() => _PersonalUnitDueTabState();
}

class _PersonalUnitDueTabState extends State<_PersonalUnitDueTab> {
  late Future<Map<String, dynamic>> _billFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  void _loadBill() {
    setState(() {
      _billFuture = FinanceApiService.fetchLatestBill();
    });
  }

  Future<void> _handlePayment(String billId, String amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Settlement'),
        content: Text('Pay ₹$amount for this month maintenance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final res = await FinanceApiService.payBill(billId, method: 'ONLINE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBill();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _billFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadBill,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? <String, dynamic>{};
        final hasPending = data['has_pending_bill'] ?? false;
        final bill = data['bill'];

        if (!hasPending || bill == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text(
                  'All maintenance dues settled!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill['bill_month'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unit: ${bill['block_name']} - ${bill['flat_number']}',
                      ),
                      Text('Due Date: ${bill['due_date']}'),
                      const Divider(height: 20),
                      Text(
                        '₹${bill['total_payable'] ?? bill['payable_amount']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _handlePayment(
                        bill['bill_id'],
                        bill['payable_amount'].toString(),
                      ),
                child: const Text('Pay Maintenance'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlockSecretaryReceiptsTab extends StatefulWidget {
  const _BlockSecretaryReceiptsTab();

  @override
  State<_BlockSecretaryReceiptsTab> createState() =>
      _BlockSecretaryReceiptsTabState();
}

class _BlockSecretaryReceiptsTabState
    extends State<_BlockSecretaryReceiptsTab> {
  late Future<List<dynamic>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _receiptsFuture = FinanceApiService.fetchPaymentHistory();
  }

  void _reloadReceipts() {
    setState(() {
      _receiptsFuture = FinanceApiService.fetchPaymentHistory();
    });
  }

  String _formatDate(BuildContext context, dynamic value) {
    final rawDate = value?.toString() ?? '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return MaterialLocalizations.of(context).formatMediumDate(parsed.toLocal());
  }

  FinancialDocument _buildReceipt(Map<String, dynamic> receipt) {
    return FinancialDocument.fromPaymentReceipt(receipt);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _receiptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _reloadReceipts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final receipts = snapshot.data ?? [];
        if (receipts.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _reloadReceipts(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 260,
                  child: Center(
                    child: Text('No previous payment receipts found.'),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reloadReceipts(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: receipts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final receipt = Map<String, dynamic>.from(receipts[index] as Map);
              final document = _buildReceipt(receipt);
              final amountValue = receipt['amount'];
              final amount = amountValue is num
                  ? amountValue.toDouble()
                  : double.tryParse(amountValue?.toString() ?? '') ?? 0;
              final paymentDate =
                  receipt['payment_date'] ?? receipt['generated_at'];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.green.shade800,
                        ),
                      ),
                      title: Text(
                        '${receipt['bill_month'] ?? '—'} · ₹${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Receipt: ${receipt['receipt_number'] ?? '—'}\n'
                        'Payer: ${receipt['payer_name'] ?? '—'} · '
                        'Method: ${receipt['payment_method'] ?? '—'}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        _formatDate(context, paymentDate),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                FinancialDocumentHelper.viewDocument(
                                  context,
                                  document,
                                ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                            ),
                            label: const Text('View receipt'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await FinancialDocumentHelper.downloadDocument(
                                context,
                                document,
                              );
                            },
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 16,
                            ),
                            label: const Text('Download PDF'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// TAB 2: BLOCK DUES STATUS WITH SEARCH & FILTER
class _BlockDuesStatusTab extends StatefulWidget {
  const _BlockDuesStatusTab();

  @override
  State<_BlockDuesStatusTab> createState() => _BlockDuesStatusTabState();
}

class _BlockDuesStatusTabState extends State<_BlockDuesStatusTab> {
  late Future<Map<String, dynamic>> _reportFuture;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL';
  late DateTime _selectedMonth;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = FinanceApiService.fetchBlockReport(
        billMonth: _formatBillMonth(_selectedMonth),
      );
    });
  }

  String _formatBillMonth(DateTime month) =>
      '${_monthNames[month.month - 1]} ${month.year}';

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select billing month',
    );
    if (selected == null || !mounted) return;

    setState(() {
      _selectedMonth = DateTime(selected.year, selected.month);
      _reportFuture = FinanceApiService.fetchBlockReport(
        billMonth: _formatBillMonth(_selectedMonth),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadReport,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? <String, dynamic>{};
        final summary = data['summary'] ?? {};
        final rawBills = (data['bills'] as List<dynamic>?) ?? [];

        final filteredBills = rawBills.where((item) {
          final flatNum = (item['flat_number'] ?? '').toString().toLowerCase();
          final residentName = (item['resident_name'] ?? '')
              .toString()
              .toLowerCase();
          final status = (item['status'] ?? 'unbilled')
              .toString()
              .trim()
              .toUpperCase();
          final searchQuery = _searchController.text.trim().toLowerCase();

          final matchesSearch =
              searchQuery.isEmpty ||
              flatNum.contains(searchQuery) ||
              residentName.contains(searchQuery);

          final matchesStatus = switch (_selectedStatusFilter) {
            'PAID' => status == 'PAID',
            'PENDING' => status == 'PENDING',
            'UNBILLED' => status == 'UNBILLED',
            _ => true,
          };

          return matchesSearch && matchesStatus;
        }).toList();

        final totalFlats = summary['total_flats'] ?? rawBills.length;
        final paidCount = summary['paid_count'] ?? 0;
        final pendingCount = summary['pending_count'] ?? 0;
        final unbilledCount =
            summary['unbilled_count'] ??
            rawBills
                .where(
                  (item) =>
                      (item['status'] ?? '').toString().toLowerCase() ==
                      'unbilled',
                )
                .length;

        return RefreshIndicator(
          onRefresh: () async => _loadReport(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade900, Colors.blueGrey.shade800],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['block_name'] ?? 'Block'} Maintenance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Billing period: ${_formatBillMonth(_selectedMonth)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _selectMonth,
                          tooltip: 'Change billing month',
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _summaryChip(
                          'Paid',
                          '$paidCount',
                          Icons.check_circle_outline,
                        ),
                        _summaryChip(
                          'Pending',
                          '$pendingCount',
                          Icons.pending_outlined,
                        ),
                        _summaryChip(
                          'Not billed',
                          '$unbilledCount',
                          Icons.receipt_long_outlined,
                        ),
                        _summaryChip(
                          'Collection',
                          '${summary['collection_rate'] ?? 0}%',
                          Icons.trending_up,
                        ),
                        _summaryChip(
                          'Flats',
                          '$totalFlats',
                          Icons.home_work_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by flat or resident',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ALL', label: Text('All')),
                          ButtonSegment(value: 'PAID', label: Text('Paid')),
                          ButtonSegment(
                            value: 'PENDING',
                            label: Text('Pending'),
                          ),
                          ButtonSegment(
                            value: 'UNBILLED',
                            label: Text('Not billed'),
                          ),
                        ],
                        selected: {_selectedStatusFilter},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _selectedStatusFilter = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredBills.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(
                                rawBills.isEmpty
                                    ? 'No maintenance records for this month.'
                                    : 'No flats match your search and status filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filteredBills.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final item = filteredBills[i];
                          final status = (item['status'] ?? 'unbilled')
                              .toString()
                              .trim()
                              .toLowerCase();
                          final statusLabel = switch (status) {
                            'paid' => 'PAID',
                            'pending' => 'PENDING',
                            'unbilled' => 'NOT BILLED',
                            _ => status.toUpperCase(),
                          };
                          final statusColor = switch (status) {
                            'paid' => Colors.green.shade800,
                            'pending' => Colors.orange.shade900,
                            _ => Colors.blueGrey.shade700,
                          };
                          final amountText = status == 'unbilled'
                              ? 'Bill not generated'
                              : 'Amount: ₹${item['total_payable'] ?? item['payable_amount']}';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              title: Text(
                                'Flat ${item['flat_number']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  '${item['resident_name'] ?? 'Resident'}\n'
                                  '$amountText · Due ${item['due_date'] ?? '--'}',
                                ),
                              ),
                              isThreeLine: true,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
