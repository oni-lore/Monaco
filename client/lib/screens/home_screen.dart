import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/providers/dm_wheel_mode_provider.dart';
import 'package:monaco/services/chat_api.dart';
import 'package:monaco/models/message.dart';
import 'package:monaco/screens/conversation_screen.dart';
import 'package:monaco/utils/design_system.dart';
import 'package:monaco/widgets/dm_wheel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final ChatApiService _api = ChatApiService();
  List<Conversation> _conversations = [];
  List<Conversation> get _councils =>
      _conversations.where((c) => c.isGroup).toList();
  List<Conversation> get _dms =>
      _conversations.where((c) => !c.isGroup).toList()
        ..sort((a, b) {
          final aTime = a.lastMessageAt ?? DateTime(1970);
          final bTime = b.lastMessageAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  // DM Quick-Access wheel open/close state (local to this screen)
  bool _dmWheelOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _dmWheelOpen) {
      setState(() {
        _dmWheelOpen = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final auth = context.read<AuthProvider>();

    final token = auth.tokens?.accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Your session has expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await _api.getConversations(accessToken: token);
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openConversation(Conversation conversation) async {
    if (_dmWheelOpen) {
      setState(() {
        _dmWheelOpen = false;
      });
    }

    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    try {
      final detail = await _api.getConversation(
        conversationId: conversation.id,
        accessToken: token,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: detail.id,
              conversationTitle: detail.displayName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open conversation: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ── Monaco header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(MonacoDesign.lg, MonacoDesign.lg, MonacoDesign.lg, MonacoDesign.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MonacoDesign.charcoalCard,
              borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
              border: Border.all(color: MonacoDesign.borderMuted, width: 1),
            ),
            child: const Center(
              child: Text(
                'M',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: MonacoDesign.accentBright,
                ),
              ),
            ),
          ),
          const SizedBox(width: MonacoDesign.sm),
          const Text(
            'Monaco',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: MonacoDesign.accentBright,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, size: 24, color: MonacoDesign.textSecondary),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  // ── Search bar for people, messages, and Councils ─────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MonacoDesign.lg),
      child: TextField(
        decoration: MonacoDesign.inputDecoration(
          context: context,
          label: 'Search',
          hint: 'People, messages, Councils',
          prefixIcon: Icons.search_rounded,
        ),
      ),
    );
  }

  // ── Notes section: intentional empty state (no Notes API exists) ────────
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MonacoDesign.lg),
          child: Row(
            children: [
              Text(
                'Notes',
                style: MonacoDesign.labelMedium(context).copyWith(
                  color: MonacoDesign.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MonacoDesign.sm),
        Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalSurface,
            borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
            border: Border.all(color: MonacoDesign.borderMuted, width: 1),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.note_add_rounded,
                  size: 32,
                  color: MonacoDesign.textMuted,
                ),
                SizedBox(height: MonacoDesign.sm),
                Text(
                  'Notes coming soon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MonacoDesign.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Councils section: asymmetric mosaic layout ────────────────────────
  Widget _buildCouncilsSection() {
    if (_councils.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(MonacoDesign.lg, MonacoDesign.lg, MonacoDesign.lg, MonacoDesign.sm),
          child: Row(
            children: [
              Text(
                'Councils',
                style: MonacoDesign.labelMedium(context).copyWith(
                  color: MonacoDesign.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${_councils.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: MonacoDesign.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MonacoDesign.sm),
        _buildResponsiveCouncilMosaic(),
      ],
    );
  }

  Widget _buildResponsiveCouncilMosaic() {
    final councils = _councils;
    if (councils.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 360;

        return SingleChildScrollView(
          child: Column(
            children: [
              if (isNarrow) ...[
                for (int i = 0; i < councils.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MonacoDesign.md),
                    child: SizedBox(
                      width: double.infinity,
                      height: 160,
                      child: _buildCouncilCard(
                        index: i,
                        council: councils[i],
                        style: CouncilStyle.medium,
                      ),
                    ),
                  ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (councils.isNotEmpty)
                      SizedBox(
                        width: availableWidth * 0.60 - MonacoDesign.md,
                        child: _buildCouncilCard(
                          index: 0,
                          council: councils[0],
                          style: CouncilStyle.wide,
                        ),
                      ),
                    const SizedBox(width: MonacoDesign.md),
                    if (councils.length > 1)
                      SizedBox(
                        width: availableWidth * 0.40 - MonacoDesign.md,
                        child: _buildCouncilCard(
                          index: 1,
                          council: councils[1],
                          style: CouncilStyle.tall,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MonacoDesign.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: availableWidth * 0.45 - MonacoDesign.md,
                      child: councils.length > 2
                          ? _buildCouncilCard(
                              index: 2,
                              council: councils[2],
                              style: CouncilStyle.medium,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: MonacoDesign.md),
                    SizedBox(
                      width: availableWidth * 0.25 - MonacoDesign.md,
                      child: councils.length > 3
                          ? _buildCouncilCard(
                              index: 3,
                              council: councils[3],
                              style: CouncilStyle.small,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: MonacoDesign.md),
                    SizedBox(
                      width: availableWidth * 0.20 - MonacoDesign.md,
                      child: councils.length > 4
                          ? _buildCouncilCard(
                              index: 4,
                              council: councils[4],
                              style: CouncilStyle.tiny,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouncilCard({
    required int index,
    required Conversation council,
    required CouncilStyle style,
  }) {
    final emblem = _buildCouncilEmblem(index);

    return CouncilCard(
      style: style,
      emblem: emblem,
      title: council.displayName.isNotEmpty ? council.displayName : 'Council',
      preview: council.hasLastMessage ? council.lastMessagePreview : 'No messages yet',
      time: council.lastMessageTime,
      onTap: () => _openConversation(council),
    );
  }

  Widget _buildCouncilEmblem(int index) {
    switch (index % 5) {
      case 0:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalElevated,
            shape: BoxShape.circle,
            border: Border.all(color: MonacoDesign.borderSubtle, width: 1),
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: MonacoDesign.accentBright,
                letterSpacing: -1,
              ),
            ),
          ),
        );
      case 1:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalSurface,
            borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
            border: Border.all(color: MonacoDesign.inkBlack, width: 2),
          ),
          child: const Center(
            child: Text(
              'C',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: MonacoDesign.accentBright,
                letterSpacing: -1,
              ),
            ),
          ),
        );
      case 2:
        return Transform.rotate(
          angle: 0.785,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MonacoDesign.charcoalCard,
              borderRadius: BorderRadius.circular(MonacoDesign.radiusSm),
              border: Border.all(color: MonacoDesign.borderMuted, width: 1),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: MonacoDesign.textSecondary,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        );
      case 3:
        return Container(
          width: 32,
          height: 48,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalElevated,
            borderRadius: BorderRadius.circular(MonacoDesign.radiusFull),
            border: Border.all(color: MonacoDesign.borderMuted, width: 1),
          ),
          child: const Center(
            child: Text(
              'Y',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: MonacoDesign.accentBright,
              ),
            ),
          ),
        );
      case 4:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(MonacoDesign.radiusMd),
              topRight: Radius.circular(MonacoDesign.radiusMd),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border.all(color: MonacoDesign.borderMuted, width: 1),
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: MonacoDesign.textInk,
                letterSpacing: -1,
              ),
            ),
          ),
        );
      default:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalCard,
            borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
          ),
          child: const Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 16,
                color: MonacoDesign.textMuted,
              ),
            ),
          ),
        );
    }
  }

  // ── Recent DM previews section ────────────────────────────────────────
  Widget _buildRecentDMSection() {
    final dms = _dms;
    if (dms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(MonacoDesign.lg, MonacoDesign.lg, MonacoDesign.lg, MonacoDesign.sm),
          child: Row(
            children: [
              Text(
                'Recent DM',
                style: MonacoDesign.labelMedium(context).copyWith(
                  color: MonacoDesign.textMuted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MonacoDesign.accentSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MonacoDesign.sm),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dms.length,
            padding: const EdgeInsets.symmetric(horizontal: MonacoDesign.lg),
            itemBuilder: (context, index) {
              final dm = dms[index];
              return _buildDMPreviewCard(dm);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDMPreviewCard(Conversation dm) {
    final otherParticipant = dm.otherParticipant;
    final username = otherParticipant?['username'] as String? ?? 'Unknown';

    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: MonacoDesign.md),
      decoration: BoxDecoration(
        color: MonacoDesign.charcoalCard,
        borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
        border: Border.all(color: MonacoDesign.borderMuted, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
          onTap: () => _openConversation(dm),
          child: Padding(
            padding: const EdgeInsets.all(MonacoDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: MonacoDesign.charcoalElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          username.isNotEmpty
                              ? username.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MonacoDesign.accentBright,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MonacoDesign.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: MonacoDesign.textInk,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: MonacoDesign.xs),
                          Text(
                            dm.hasLastMessage ? dm.lastMessagePreview : 'No messages yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: MonacoDesign.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (dm.lastMessageAt != null)
                      Text(
                        dm.lastMessageTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: MonacoDesign.textMuted,
                        ),
                      ),
                  ],
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
    final dmWheelMode = context.watch<DMWheelModeProvider>().mode;

    return Scaffold(
      backgroundColor: MonacoDesign.charcoalDeep,
      appBar: AppBar(
        backgroundColor: MonacoDesign.charcoalDeep,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _buildHeader(),
        toolbarHeight: 72,
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              // ── Chats ──────────────────────────────────────────────────────
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: MonacoDesign.lg + 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null) _buildErrorPanel(),
                            _buildSearchBar(),
                            const SizedBox(height: MonacoDesign.xl),
                            _buildNotesSection(),
                            const SizedBox(height: MonacoDesign.xxl),
                            _buildCouncilsSection(),
                            const SizedBox(height: MonacoDesign.xxl),
                            _buildRecentDMSection(),
                          ],
                        ),
                      ),
                    ),
              // ── Loading Chambers ───────────────────────────────────────────
              const LoadingChambersScreenBody(),
              // ── Profile ────────────────────────────────────────────────────
              const ProfileScreenBody(),
            ],
          ),
          // DM Quick-Access wheel overlay (only on Chats tab)
          if (_selectedIndex == 0 && dmWheelMode != DMWheelMode.off)
            DMQuickAccessWheel(
              mode: dmWheelMode,
              dms: _dms,
              onContactSelected: (conversationId) {
                final dm = _dms.firstWhere((d) => d.id == conversationId);
                _openConversation(dm);
              },
              isOpen: _dmWheelOpen,
              onOpenChanged: (open) => setState(() => _dmWheelOpen = open),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: MonacoDesign.charcoalSurface,
          border: Border(
            top: BorderSide(color: MonacoDesign.borderMuted, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
          backgroundColor: MonacoDesign.charcoalSurface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: MonacoDesign.accentBright,
          unselectedItemColor: MonacoDesign.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 24),
              activeIcon: const Icon(Icons.chat_bubble_rounded, size: 24),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded, size: 24),
              activeIcon: const Icon(Icons.history_rounded, size: 24),
              label: 'Loading Chambers',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded, size: 24),
              activeIcon: const Icon(Icons.person_rounded, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MonacoDesign.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MonacoDesign.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: MonacoDesign.error,
              size: 32,
            ),
          ),
          const SizedBox(height: MonacoDesign.md),
          Text(
            'Couldn’t load Chats',
            style: MonacoDesign.headlineMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: MonacoDesign.textInk,
            ),
          ),
          const SizedBox(height: MonacoDesign.sm),
          Text(
            _error ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: MonacoDesign.bodyMedium(context).copyWith(
              color: MonacoDesign.textSecondary,
            ),
          ),
          const SizedBox(height: MonacoDesign.lg),
          FilledButton(
            onPressed: _loadConversations,
            style: MonacoDesign.primaryButton(context),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// Council visual styles for the asymmetric mosaic
enum CouncilStyle {
  wide,    // Wide horizontal card
  tall,    // Tall vertical card
  medium,  // Medium square card
  small,   // Small card
  tiny,    // Tiny card
}

/// Individual Council card with monochrome treatment
class CouncilCard extends StatelessWidget {
  final CouncilStyle style;
  final Widget emblem;
  final String title;
  final String preview;
  final String time;
  final VoidCallback onTap;

  const CouncilCard({
    super.key,
    required this.style,
    required this.emblem,
    required this.title,
    required this.preview,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double height;
    switch (style) {
      case CouncilStyle.wide:
        height = 160;
        break;
      case CouncilStyle.tall:
        height = 260;
        break;
      case CouncilStyle.medium:
        height = 200;
        break;
      case CouncilStyle.small:
        height = 140;
        break;
      case CouncilStyle.tiny:
        height = 120;
        break;
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: MonacoDesign.charcoalCard,
        borderRadius: BorderRadius.circular(MonacoDesign.radiusXl),
        border: Border.all(color: MonacoDesign.borderMuted, width: 1),
        boxShadow: [
          BoxShadow(
            color: MonacoDesign.inkBlack.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MonacoDesign.radiusXl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(MonacoDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                emblem,
                const SizedBox(height: MonacoDesign.md),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MonacoDesign.textInk,
                    ),
                    maxLines: style == CouncilStyle.tiny ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: MonacoDesign.xs),
                Flexible(
                  child: Text(
                    preview,
                    style: TextStyle(
                      fontSize: 11,
                      color: MonacoDesign.textSecondary,
                    ),
                    maxLines: style == CouncilStyle.tiny ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: MonacoDesign.textMuted,
                      ),
                    ),
                    if (style != CouncilStyle.tiny)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: MonacoDesign.textMuted,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading Chambers inline body — used as a bottom-nav tab.
class LoadingChambersScreenBody extends StatelessWidget {
  const LoadingChambersScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MonacoDesign.charcoalSurface,
              borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
              border: Border.all(
                color: MonacoDesign.borderSubtle,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 32,
              color: MonacoDesign.textSecondary,
            ),
          ),
          const SizedBox(height: MonacoDesign.md),
          Text(
            'Loading Chambers',
            style: MonacoDesign.headlineMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: MonacoDesign.textInk,
            ),
          ),
          const SizedBox(height: MonacoDesign.sm),
          Text(
            'Historical archives.\nPlanned features coming soon.',
            textAlign: TextAlign.center,
            style: MonacoDesign.bodyMedium(context).copyWith(
              color: MonacoDesign.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile inline body — used as a bottom-nav tab.
class ProfileScreenBody extends StatelessWidget {
  const ProfileScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MonacoDesign.charcoalSurface,
              borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
              border: Border.all(
                color: MonacoDesign.borderSubtle,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: MonacoDesign.textSecondary,
            ),
          ),
          const SizedBox(height: MonacoDesign.md),
          Text(
            'Profile',
            style: MonacoDesign.headlineMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: MonacoDesign.textInk,
            ),
          ),
          const SizedBox(height: MonacoDesign.sm),
          Text(
            'Identity and account settings.\nComing soon.',
            textAlign: TextAlign.center,
            style: MonacoDesign.bodyMedium(context).copyWith(
              color: MonacoDesign.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
