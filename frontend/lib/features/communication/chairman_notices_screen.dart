import 'package:flutter/material.dart';
import '../../data/datasource/communication_api_service.dart';
import '../../data/datasource/api_service.dart';
import 'notice_widgets.dart';

class ChairmanNoticesScreen extends StatefulWidget {
  const ChairmanNoticesScreen({super.key});

  @override
  State<ChairmanNoticesScreen> createState() => _ChairmanNoticesScreenState();
}

class _ChairmanNoticesScreenState extends State<ChairmanNoticesScreen> {
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

      // Fallback: If society_id is missing, match via society_name from public societies list
      if (societyId.isEmpty) {
        final societies = await ApiService.fetchSocieties();
        final currentSocietyName = profile['society_name'] ?? '';
        final match = societies.firstWhere(
          (s) => s.name.toLowerCase() == currentSocietyName.toLowerCase(),
          orElse: () => societies.isNotEmpty
              ? societies.first
              : Society(id: '', name: ''),
        );
        societyId = match.id;
      }

      if (societyId.isNotEmpty && mounted) {
        final blocks = await ApiService.fetchBlocks(societyId);
        if (mounted) setState(() => _blocks = blocks);
      }
    } catch (error) {
      debugPrint('[ChairmanNotices] Failed to load blocks: $error');
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
            content: Text(res['message'] ?? 'Notice archived successfully!'),
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
    bool isSubmitting = false;
    String? sheetError;

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
                      title: 'Publish Announcement',
                      subtitle:
                          'Prepare a clear, official notice for residents.',
                      icon: Icons.campaign_outlined,
                      onClose: () {
                        titleController.dispose();
                        descController.dispose();
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Title
                    _buildFieldLabel('Notice Title', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Annual Society Meeting, Water Outage',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Notice title is required';
                        if (val.length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        if (val.length > 150) {
                          return 'Title cannot exceed 150 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Description
                    _buildFieldLabel('Announcement Details', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write the complete announcement...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) {
                          return 'Notice details cannot be empty';
                        }
                        if (val.length < 10) {
                          return 'Please provide more details (minimum 10 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Priority & Scope Pickers
                    Row(
                      children: [
                        // Priority Selector
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Priority', isRequired: true),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedPriority,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
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
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedPriority = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Block Scope Selector
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Target Scope'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String?>(
                                value: selectedBlockId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'All Blocks',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ..._blocks.map(
                                    (b) => DropdownMenuItem(
                                      value: b.id,
                                      child: Text(
                                        b.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setModalState(() => selectedBlockId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // INLINE MODAL ERROR BANNER
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
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
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
                                    await CommunicationApiService.publishNotice(
                                      title: titleController.text.trim(),
                                      description: descController.text.trim(),
                                      priority: selectedPriority,
                                      blockId: selectedBlockId,
                                    );
                                if (mounted) {
                                  titleController.dispose();
                                  descController.dispose();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ??
                                            'Notice published successfully!',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                  _loadNotices();
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
                        backgroundColor: Colors.indigo.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              'Publish Notice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
      appBar: AppBar(
        title: const Text('Society Announcements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(
            context,
          ), // Replaced pushReplacementNamed with clean pop
        ),
      ),
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
                    title: 'Society Announcements',
                    subtitle:
                        'Publish and manage official updates for residents across your society.',
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
