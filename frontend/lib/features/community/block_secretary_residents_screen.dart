import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class BlockSecretaryResidentsScreen extends StatefulWidget {
  const BlockSecretaryResidentsScreen({super.key});

  @override
  State<BlockSecretaryResidentsScreen> createState() =>
      _BlockSecretaryResidentsScreenState();
}

class _BlockSecretaryResidentsScreenState
    extends State<BlockSecretaryResidentsScreen> {
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;
  Timer? _searchDebounce;
  int _requestId = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDirectory();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDirectory() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await CommunityApiService.fetchResidentsDirectory(
        search: _searchQuery,
      );
      if (mounted && requestId == _requestId) {
        setState(() {
          _residents = res['residents'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _fetchDirectory);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
    _fetchDirectory();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF8F00);
    const ink = Color(0xFF172B3A);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to dashboard',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/block-secretary-home',
            (route) => false,
          ),
        ),
        title: const Text('Block Residents Directory'),
        actions: [
          IconButton(
            tooltip: 'Refresh directory',
            onPressed: _isLoading ? null : _fetchDirectory,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Card(
              elevation: 0,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.amber.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.amber.shade100,
                      child: const Icon(
                        Icons.groups_outlined,
                        color: accent,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your block residents',
                            style: TextStyle(
                              color: ink,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoading
                                ? 'Updating directory…'
                                : '${_residents.length} ${_residents.length == 1 ? 'resident' : 'residents'}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by name, flat or phone',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: accent, width: 1.4),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null && _residents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFF9A5A00),
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF7A4A00),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Retry',
                            visualDensity: VisualDensity.compact,
                            onPressed: _fetchDirectory,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF9A5A00),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _isLoading && _residents.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: accent),
                        )
                      : _errorMessage != null && _residents.isEmpty
                      ? _buildMessageState(
                          icon: Icons.cloud_off_outlined,
                          title: 'Couldn’t load the directory',
                          message: _errorMessage!,
                          actionLabel: 'Try again',
                          onAction: _fetchDirectory,
                          accent: accent,
                        )
                      : _residents.isEmpty
                      ? _buildMessageState(
                          icon: Icons.person_search_rounded,
                          title: _searchQuery.isEmpty
                              ? 'No residents yet'
                              : 'No matches found',
                          message: _searchQuery.isEmpty
                              ? 'Residents in your block will appear here.'
                              : 'Try a different name, flat number or phone.',
                          actionLabel: _searchQuery.isEmpty
                              ? null
                              : 'Clear search',
                          onAction: _searchQuery.isEmpty ? null : _clearSearch,
                          accent: accent,
                        )
                      : RefreshIndicator(
                          color: accent,
                          onRefresh: _fetchDirectory,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _residents.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final resident = _residents[i];
                              final name = (resident['user_name'] ?? 'Resident')
                                  .toString()
                                  .trim();
                              final displayName = name.isEmpty
                                  ? 'Resident'
                                  : name;
                              final initials = displayName
                                  .substring(0, 1)
                                  .toUpperCase();
                              final flatNumber =
                                  (resident['flat_number'] ?? '--').toString();
                              final phone = (resident['user_phone'] ?? '')
                                  .toString();

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade50,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 15,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            phone.isEmpty
                                                ? 'Phone not provided'
                                                : phone,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      flatNumber,
                                      style: const TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required Color accent,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF172B3A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF71818A),
                height: 1.45,
                fontSize: 13,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
