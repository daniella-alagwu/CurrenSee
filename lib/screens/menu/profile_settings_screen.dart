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
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _store = UserStore.instance;
  late final _nameCtrl = TextEditingController(text: _store.name ?? '');
  final _curPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  late String _currency = RatesService.startingBase(_store.baseCurrency);
  late String? _countryCode = _store.countryCode;
  late String? _countryName = _store.countryName;

  bool _savingProfile = false;
  bool _uploading = false;
  bool _changingPw = false;

  bool get _hasPassword =>
      FirebaseAuth.instance.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

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
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      await ApiClient.updateProfile({'avatar': 'data:image/jpeg;base64,${base64Encode(bytes)}'});
      await _store.load(force: true);
      if (mounted) toast(context, 'Profile picture updated.');
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile() async {
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
        if (_countryCode != null) 'countryCode': _countryCode,
        if (_countryName != null) 'countryName': _countryName,
        'currencyCode': _currency,
        'currencyName': info.name,
        'currencySymbol': info.symbol.trim(),
      });
      await _store.load(force: true);
      if (mounted) toast(context, 'Profile saved.');
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    if (_curPw.text.isEmpty) {
      showAuthError(context, 'Enter your current password.');
      return;
    }
    if (_newPw.text.length < 6) {
      showAuthError(context, 'New password must be at least 6 characters.');
      return;
    }
    if (_newPw.text != _confirmPw.text) {
      showAuthError(context, 'New passwords do not match.');
      return;
    }
    setState(() => _changingPw = true);
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: _curPw.text));
      await user.updatePassword(_newPw.text);
      _curPw.clear();
      _newPw.clear();
      _confirmPw.clear();
      if (mounted) toast(context, 'Password changed.');
    } on FirebaseAuthException catch (e) {
      final wrong = e.code == 'wrong-password' || e.code == 'invalid-credential';
      if (mounted) {
        showAuthError(context,
            wrong ? 'Current password is incorrect.' : (e.message ?? 'Could not change password.'));
      }
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    final old = key == 'pushEnabled' ? _store.pushEnabled : _store.alertsEnabled;
    _store.setPref(key, value);
    try {
      await ApiClient.updatePreferences({key: value});
    } catch (e) {
      _store.setPref(key, old);
      if (mounted) showAuthError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('Profile settings')),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(avatar: _store.avatar, radius: 52, background: AppColors.emeraldBg),
                  if (_uploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(color: AppColors.goldWarm),
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
                          child: Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.textDark),
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
                    (_countryName?.isNotEmpty ?? false) ? _countryName! : 'Select country',
                    style: const TextStyle(color: AppColors.textDark, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CurrencyDropdown(label: 'Home currency', value: _currency, onChanged: (c) => setState(() => _currency = c)),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  'Quick convert starts from this currency. Your saved history is not changed.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(label: 'Save changes', isLoading: _savingProfile, onPressed: _saveProfile),
            ]),
            if (_hasPassword) ...[
              const SizedBox(height: 16),
              _section('Change password', [
                TextField(
                  controller: _curPw,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPw,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPw,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                ),
                const SizedBox(height: 16),
                GoldButton(label: 'Change password', isLoading: _changingPw, onPressed: _changePassword),
              ]),
            ],
            const SizedBox(height: 16),
            _section('Notifications', [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Push notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Updates from CurrenSee on this device'),
                value: _store.pushEnabled,
                onChanged: (v) => _togglePref('pushEnabled', v),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rate alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Get notified about rate movements'),
                value: _store.alertsEnabled,
                onChanged: (v) => _togglePref('alertNotificationsEnabled', v),
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
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      );
}
