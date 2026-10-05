import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_client.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Map<String, dynamic>? _admin;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admin = await ApiClient.getAdminIdentity();
      if (mounted) setState(() => _admin = admin);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _admin?['email'] as String? ??
        FirebaseAuth.instance.currentUser?.email ??
        '';

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text('CurrenSee Admin'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator(color: AppColors.forestGreen)
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Could not confirm admin access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAdmin,
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 56,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Admin home',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Admin access confirmed. Admin tools can be added here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDark),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}