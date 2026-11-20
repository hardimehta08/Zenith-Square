import 'package:flutter/material.dart';
import '../../data/datasource/communication_api_service.dart';
import '../../data/datasource/api_service.dart';
import 'notice_widgets.dart';

class SecretaryNoticesScreen extends StatefulWidget {
  const SecretaryNoticesScreen({super.key});

  @override
  State<SecretaryNoticesScreen> createState() => _SecretaryNoticesScreenState();
}

class _SecretaryNoticesScreenState extends State<SecretaryNoticesScreen> {
  late Future<List<dynamic>> _noticesFuture;
  List<Block> _blocks = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
    _loadBlocks();
  }

  void _loadNotices() {
    if (!mounted) return;
    setState(() {
      _noticesFuture = CommunicationApiService.fetchNotices();
    });
  }

  Future<void> _loadBlocks() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      String societyId = profile['society_id'] ?? '';
      if (societyId.isNotEmpty && mounted) {
        final blocks = await ApiService.fetchBlocks(societyId);
        if (mounted) setState(() => _blocks = blocks);
      }
    } catch (e) {
      debugPrint('[SecretaryNotices] Error loading blocks: $e');
    }
  }

  Future<void> _handleDeleteNotice(String noticeId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Notice'),
        content: Text('Are you sure you want to archive "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await CommunicationApiService.deleteNotice(noticeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Notice archived!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadNotices();
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

  void _openPublishNoticeSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'normal';
    String? selectedBlockId;
    String? sheetError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.blueGrey.shade50,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NoticeComposerHeader(
                      title: 'Post Society Notice',
                      subtitle: 'Share an official update with residents.',
                      icon: Icons.campaign_outlined,
                      onClose: () {
                        titleController.dispose();
                        descController.dispose();
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (sheetError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
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
                    ],

                    TextFormField(
                      controller: titleController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Title must be at least 3 chars'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Details *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Details must be at least 10 chars'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'normal',
                                child: Text('Normal'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High'),
                              ),
                              DropdownMenuItem(
                                value: 'urgent',
                                child: Text('Urgent'),
                              ),
                            ],
                            onChanged: (val) =>
                                setModalState(() => selectedPriority = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: selectedBlockId,
                            decoration: const InputDecoration(
                              labelText: 'Target Scope',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Blocks'),
                              ),
                              ..._blocks.map(
                                (b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.name),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setModalState(() => selectedBlockId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await CommunicationApiService.publishNotice(
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  priority: selectedPriority,
                                  blockId: selectedBlockId,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _loadNotices();
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                sheetError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Publish Announcement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(title: const Text('Secretary Notice Board')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublishNoticeSheet,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publish notice'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NoticeErrorState(
              message: snapshot.error.toString().replaceAll('Exception: ', ''),
              onRetry: _loadNotices,
            );
          }

          final notices = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => _loadNotices(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
              itemCount: notices.isEmpty ? 2 : notices.length + 1,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return NoticePageHeader(
                    title: 'Secretary Notice Board',
                    subtitle:
                        'Publish clear, official updates for residents across your society.',
                    count: notices.length,
                  );
                }

                if (notices.isEmpty) {
                  return const NoticeEmptyState(
                    title: 'No notices published',
                    subtitle:
                        'Use “Publish notice” to share an update with residents.',
                  );
                }

                final item = notices[i - 1];
                return NoticeEntryCard(
                  title: item['title']?.toString() ?? 'Untitled notice',
                  description: item['description']?.toString() ?? '',
                  priority: item['priority']?.toString() ?? 'normal',
                  scope: item['block_name']?.toString() ?? 'All Blocks',
                  author: item['author_name']?.toString(),
                  createdAt: item['created_at'],
                  action: IconButton(
                    tooltip: 'Archive notice',
                    onPressed: () => _handleDeleteNotice(
                      item['notice_id'].toString(),
                      item['title']?.toString() ?? 'Notice',
                    ),
                    icon: const Icon(Icons.archive_outlined),
                    color: Colors.blueGrey.shade700,
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
