import 'dart:convert';

import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/services/user_store.dart';
import 'package:currensee/utils/toast.dart';
import 'package:currensee/screens/home/widgets/currency_dropdown.dart';
import 'package:currensee/screens/home/widgets/user_avatar.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _store = UserStore.instance;

  late final TextEditingController _nameCtrl =
      TextEditingController(text: _store.name ?? '');

  final _curPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  late String _currency =
      RatesService.startingBase(_store.baseCurrency);

  late String? _countryCode = _store.countryCode;
  late String? _countryName = _store.countryName;

  late String _savedName = _nameCtrl.text.trim();
  late String _savedCurrency = _currency;
  late String? _savedCountryCode = _countryCode;
  late String? _savedCountryName = _countryName;

  bool _savingProfile = false;
  bool _uploading = false;
  bool _changingPw = false;

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool get _hasPassword =>
      FirebaseAuth.instance.currentUser?.providerData.any(
        (p) => p.providerId == 'password',
      ) ??
      false;

  bool get _profileChanged =>
      _nameCtrl.text.trim() != _savedName ||
      _currency != _savedCurrency ||
      _countryCode != _savedCountryCode ||
      _countryName != _savedCountryName;

  bool get _passwordFieldsChanged =>
      _curPw.text.isNotEmpty ||
      _newPw.text.isNotEmpty ||
      _confirmPw.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_refreshState);
    _curPw.addListener(_refreshState);
    _newPw.addListener(_refreshState);
    _confirmPw.addListener(_refreshState);
  }

  void _refreshState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _curPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 60,
    );

    if (file == null || !mounted) return;

    setState(() => _uploading = true);

    try {
      final bytes = await file.readAsBytes();

      await ApiClient.updateProfile({
        'avatar': 'data:image/jpeg;base64,${base64Encode(bytes)}',
      });

      await _store.load(force: true);

      if (mounted) {
        toast(context, 'Profile picture updated.');
      }
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    if (_uploading || _store.avatar == null || _store.avatar!.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove profile picture?'),
        content: const Text(
          'Your current profile picture will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.negativeRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _uploading = true);

    try {
      // The backend must treat null as a request to clear the stored avatar.
      await ApiClient.updateProfile({'avatar': null});

      await _store.load(force: true);

      if (mounted) {
        toast(context, 'Profile picture removed.');
      }
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileChanged || _savingProfile) return;

    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      showAuthError(context, 'Enter your name.');
      return;
    }

    final info = RatesService.info(_currency);

    setState(() => _savingProfile = true);

    try {
      await ApiClient.updateProfile({
        'name': name,
        'countryCode': _countryCode,
        'countryName': _countryName,
        'currencyCode': _currency,
        'currencyName': info.name,
        'currencySymbol': info.symbol.trim(),
      });

      await _store.load(force: true);

      if (!mounted) return;

      setState(() {
        _savedName = name;
        _savedCurrency = _currency;
        _savedCountryCode = _countryCode;
        _savedCountryName = _countryName;
      });

      toast(context, 'Profile saved.');
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFieldsChanged || _changingPw) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (user == null || email == null) return;

    if (_curPw.text.isEmpty) {
      showAuthError(context, 'Enter your current password.');
      return;
    }

    if (_newPw.text.length < 6) {
      showAuthError(
        context,
        'New password must be at least 6 characters.',
      );
      return;
    }

    if (_newPw.text != _confirmPw.text) {
      showAuthError(context, 'New passwords do not match.');
      return;
    }

    setState(() => _changingPw = true);

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: email,
          password: _curPw.text,
        ),
      );

      await user.updatePassword(_newPw.text);

      // Sign out so the user must authenticate again with the new password.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      toast(context, 'Password changed. Please log in again.');

      // Return to the root screen. The app's authentication gate should
      // display its signed-out/login screen after sign-out.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      final wrong =
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential';

      if (mounted) {
        showAuthError(
          context,
          wrong
              ? 'Current password is incorrect.'
              : (e.message ?? 'Could not change password.'),
        );
      }
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    final old = key == 'pushEnabled'
        ? _store.pushEnabled
        : _store.alertsEnabled;

    _store.setPref(key, value);

    try {
      await ApiClient.updatePreferences({key: value});
    } catch (e) {
      _store.setPref(key, old);
      if (mounted) showAuthError(context, e.toString());
    }
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        onPressed: onToggle,
        icon: Icon(
          visible
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text('Profile settings'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    avatar: _store.avatar,
                    radius: 52,
                    background: AppColors.emeraldBg,
                  ),
                  if (_uploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        color: AppColors.goldWarm,
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.goldWarm,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : _pickAvatar,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_store.avatar != null &&
                      _store.avatar!.isNotEmpty)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.negativeRed,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _uploading ? null : _deleteAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _section('Personal details', [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                cursorColor: AppColors.forestGreen,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => showCountryPicker(
                  context: context,
                  showPhoneCode: false,
                  onSelect: (c) => setState(() {
                    _countryCode = c.countryCode;
                    _countryName = c.name;
                  }),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  child: Text(
                    (_countryName?.isNotEmpty ?? false)
                        ? _countryName!
                        : 'Select country',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CurrencyDropdown(
                label: 'Home currency',
                value: _currency,
                onChanged: (c) => setState(() => _currency = c),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  'Quick convert starts from this currency. Your saved history is not changed.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'Save changes',
                isLoading: _savingProfile,
                onPressed: _profileChanged && !_savingProfile
                    ? _saveProfile
                    : null,
              ),
            ]),

            if (_hasPassword) ...[
              const SizedBox(height: 16),
              _section('Change password', [
                TextField(
                  controller: _curPw,
                  obscureText: !_showCurrentPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _passwordDecoration(
                    label: 'Current password',
                    visible: _showCurrentPassword,
                    onToggle: () => setState(
                      () => _showCurrentPassword = !_showCurrentPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPw,
                  obscureText: !_showNewPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _passwordDecoration(
                    label: 'New password',
                    visible: _showNewPassword,
                    onToggle: () => setState(
                      () => _showNewPassword = !_showNewPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPw,
                  obscureText: !_showConfirmPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _passwordDecoration(
                    label: 'Confirm new password',
                    visible: _showConfirmPassword,
                    onToggle: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GoldButton(
                  label: 'Change password',
                  isLoading: _changingPw,
                  onPressed: _passwordFieldsChanged && !_changingPw
                      ? _changePassword
                      : null,
                ),
              ]),
            ],

            const SizedBox(height: 16),
            _section('Notifications', [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Push notifications',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Updates from CurrenSee on this device',
                ),
                value: _store.pushEnabled,
                onChanged: (v) => _togglePref('pushEnabled', v),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Rate alerts',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Get notified about rate movements',
                ),
                value: _store.alertsEnabled,
                onChanged: (v) =>
                    _togglePref('alertNotificationsEnabled', v),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      );
}
