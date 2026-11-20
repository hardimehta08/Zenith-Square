import 'package:flutter/material.dart';
import '../../data/datasource/communication_api_service.dart';
import 'notice_widgets.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  late Future<List<dynamic>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    setState(() {
      _noticesFuture = CommunicationApiService.fetchNotices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('Notices & Announcements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
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
          if (notices.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadNotices(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  NoticePageHeader(
                    title: 'Community Notices',
                    subtitle:
                        'Official announcements and important updates for residents.',
                    count: 0,
                  ),
                  SizedBox(height: 24),
                  NoticeEmptyState(
                    title: 'No active notices',
                    subtitle:
                        'There are no community announcements to display right now.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadNotices(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: notices.length + 1,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return NoticePageHeader(
                    title: 'Community Notices',
                    subtitle:
                        'Official announcements and important updates for residents.',
                    count: notices.length,
                  );
                }

                final item = notices[i - 1];
                return NoticeEntryCard(
                  title: item['title']?.toString() ?? 'Untitled notice',
                  description: item['description']?.toString() ?? '',
                  priority: item['priority']?.toString() ?? 'normal',
                  scope: item['block_name']?.toString() ?? 'All Blocks',
                  author: item['author_name']?.toString() ?? 'Administration',
                  createdAt: item['created_at'],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
