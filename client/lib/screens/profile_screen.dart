import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/providers/dm_wheel_mode_provider.dart';
import 'package:monaco/services/chat_api.dart';
import 'package:monaco/utils/design_system.dart';
import 'package:monaco/widgets/dm_wheel.dart';
import 'package:monaco/widgets/monaco_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ChatApiService _api = ChatApiService();

  String? _username;
  String? _email;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _usernameEditing = false;
  bool _emailEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Session expired. Please sign in again.';
      });
      return;
    }

    try {
      final user = await _api.getMyProfile(accessToken: token);
      if (mounted) {
        setState(() {
          _username = user.username;
          _email = user.email;
          _usernameController.text = user.username;
          _emailController.text = user.email;
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

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername == _username || newUsername.isEmpty) {
      setState(() {
        _usernameEditing = false;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updatedUser = await _api.updateProfile(
        accessToken: token,
        username: newUsername,
      );
      if (mounted) {
        setState(() {
          _username = updatedUser.username;
          _usernameEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Username updated successfully'),
            backgroundColor: MonacoDesign.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
          _usernameController.text = _username ?? '';
        });
      }
    }
  }

  Future<void> _saveEmail() async {
    final newEmail = _emailController.text.trim();
    if (newEmail == _email || newEmail.isEmpty) {
      setState(() {
        _emailEditing = false;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final updatedUser = await _api.updateProfile(
        accessToken: token,
        email: newEmail,
      );
      if (mounted) {
        setState(() {
          _email = updatedUser.email;
          _emailEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email updated successfully. Please verify your new email address.'),
            backgroundColor: MonacoDesign.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
          _emailController.text = _email ?? '';
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MonacoLoader();
    }

    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: MonacoDesign.charcoalDeep,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MonacoDesign.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile header
            CircleAvatar(
              radius: 52,
              backgroundColor: MonacoDesign.inkBlack,
              child: Text(
                (_username ?? user?.username ?? 'U').isNotEmpty
                    ? (_username ?? user!.username).substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: MonacoDesign.md),
            Text(
              _username ?? user?.username ?? 'Unknown',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                    color: MonacoDesign.textInk,
              ),
            ),
            const SizedBox(height: MonacoDesign.sm),
            Text(
              _email ?? user?.email ?? 'No email',
              style: MonacoDesign.bodyMedium(context).copyWith(
                color: MonacoDesign.textSecondary,
              ),
            ),
            if (user?.emailVerified == true) ...[
              const SizedBox(height: MonacoDesign.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MonacoDesign.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: MonacoDesign.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Email verified',
                      style: TextStyle(
                        color: MonacoDesign.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MonacoDesign.xl),

            // Account section
            _buildSectionHeader('Account'),
            const SizedBox(height: MonacoDesign.sm),

            // Username field
            _buildEditableField(
              label: 'Username',
              value: _username ?? '',
              controller: _usernameController,
              focusNode: _usernameFocus,
              isEditing: _usernameEditing,
              onEditToggle: () => setState(() => _usernameEditing = !_usernameEditing),
              onSave: _saveUsername,
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Username cannot be empty';
                if (v.length < 3) return 'Username must be at least 3 characters';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),
            const SizedBox(height: MonacoDesign.md),

            // Email field
            _buildEditableField(
              label: 'Email address',
              value: _email ?? '',
              controller: _emailController,
              focusNode: _emailFocus,
              isEditing: _emailEditing,
              onEditToggle: () => setState(() => _emailEditing = !_emailEditing),
              onSave: _saveEmail,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email cannot be empty';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: MonacoDesign.xl),

            // Actions section
            _buildSectionHeader('Actions'),
            const SizedBox(height: MonacoDesign.sm),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _logout,
                style: FilledButton.styleFrom(
                  backgroundColor: MonacoDesign.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MonacoDesign.radiusMd),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Log out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: MonacoDesign.xxl),

            // DM Quick Access section
            _buildSectionHeader('DM Quick Access'),
            const SizedBox(height: MonacoDesign.sm),
            Consumer<DMWheelModeProvider>(
              builder: (context, wheelProvider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Radio<DMWheelMode>(
                        value: DMWheelMode.off,
                        groupValue: wheelProvider.mode,
                        onChanged: (v) => wheelProvider.setMode(v!),
                        activeColor: MonacoDesign.inkBlack,
                      ),
                      title: const Text('Off'),
                      subtitle: const Text('DM wheel disabled'),
                    ),
                    ListTile(
                      leading: Radio<DMWheelMode>(
                        value: DMWheelMode.left,
                        groupValue: wheelProvider.mode,
                        onChanged: (v) => wheelProvider.setMode(v!),
                        activeColor: MonacoDesign.inkBlack,
                      ),
                      title: const Text('Left edge'),
                      subtitle: const Text('Wheel opens from left side'),
                    ),
                    ListTile(
                      leading: Radio<DMWheelMode>(
                        value: DMWheelMode.right,
                        groupValue: wheelProvider.mode,
                        onChanged: (v) => wheelProvider.setMode(v!),
                        activeColor: MonacoDesign.inkBlack,
                      ),
                      title: const Text('Right edge'),
                      subtitle: const Text('Wheel opens from right side'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: MonacoDesign.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: MonacoDesign.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required VoidCallback onSave,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colors = Theme.of(context).colorScheme;
    final showError = _error != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
        border: Border.all(
          color: isEditing
              ? MonacoDesign.inkBlack
              : colors.outlineVariant.withOpacity(0.3),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: MonacoDesign.labelMedium(context).copyWith(
                    color: MonacoDesign.textSecondary,
                  ),
                  ),
                if (!isEditing)
                  TextButton(
                    onPressed: onEditToggle,
                    child: const Text('Edit'),
                  ),
              ],
            ),
          ),
          if (isEditing) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSave(),
                decoration: InputDecoration(
                  hintText: value,
                  hintStyle: TextStyle(
                    color: colors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : onSave,
                      style: MonacoDesign.primaryButton(context),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: MonacoDesign.sm),
                  OutlinedButton(
                    onPressed: _isSaving ? null : () {
                      controller.text = value;
                      focusNode.unfocus();
                      setState(() {
                        if (label == 'Username') _usernameEditing = false;
                        if (label == 'Email address') _emailEditing = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                color: MonacoDesign.textInk,
                ),
              ),
              trailing: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: MonacoDesign.textSecondary,
              ),
              onTap: onEditToggle,
            ),
          ],
          if (showError)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: MonacoDesign.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
