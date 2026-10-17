import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/services/chat_api.dart';
import 'package:monaco/screens/conversation_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ChatApiService _api = ChatApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _isCreating = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final users = await _api.searchUsers(query: query, accessToken: token);
      if (mounted) {
        setState(() {
          _results = users;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      await _api.createConversation(
        accessToken: token,
        targetUserId: user['id'] as String,
      );

      if (mounted) {
        setState(() {
          _isCreating = false;
          _successMessage = 'Conversation started with ${user['username']}';
        });
        // Navigate to conversation after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop(); // Return to home which will refresh
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Widget _buildUserResult(Map<String, dynamic> user) {
    final isCreating = _isCreating;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          (user['username'] as String? ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        user['username'] as String? ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        user['email'] as String? ?? '',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: _isCreating
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : ElevatedButton.icon(
        onPressed: () => _startConversation(user),
        icon: const Icon(Icons.message_rounded, size: 16),
        label: const Text('Message', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Conversation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchUsers(),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _isSearching
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _error = null;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_successMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _successMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          Expanded(
            child: _results.isEmpty && _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No users found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try searching by a different username',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) => _buildUserResult(_results[index]),
            ),
          ),
        ],
      ),
    );
  }
}
