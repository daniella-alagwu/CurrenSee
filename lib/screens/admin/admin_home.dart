import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/screens/main_shell.dart';
import 'package:currensee/services/api_client.dart';
import 'admin_inbox_screen.dart';
import 'admin_users_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  Map<String, dynamic>? _admin;
  Map<String, dynamic> _stats = const {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admin = await ApiClient.getAdminIdentity();
      if (mounted) setState(() => _admin = admin);
      await _loadStats();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiClient.getAdminStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      // Stats are a nice-to-have; the tools below still work.
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadStats();
  }

  String _n(String key) => _stats[key] == null ? '—' : '${_stats[key]}';

  @override
  Widget build(BuildContext context) {
    final email = _admin?['email'] as String? ??
        FirebaseAuth.instance.currentUser?.email ??
        '';
    final isPrimaryAdmin = _admin?['primaryAdmin'] == true;

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text('CurrenSee Admin'),
        actions: [
          TextButton.icon(
            onPressed: _loading || _error != null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                    ),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('User mode'),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
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
                        ElevatedButton(onPressed: _load, child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.forestGreen,
                  onRefresh: _loadStats,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_outlined,
                                size: 40, color: AppColors.goldLight),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Admin home',
                                      style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text(email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70)),
                                  if (isPrimaryAdmin)
                                    const Text('Primary administrator',
                                        style: TextStyle(
                                            color: AppColors.goldLight,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        _Stat(Icons.people_alt_outlined, 'Users', _n('users'), AppColors.forestGreen),
                        const SizedBox(width: 10),
                        _Stat(Icons.person_add_alt_1_outlined, 'New this week', _n('newThisWeek'),
                            AppColors.infoBlue),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        _Stat(Icons.block_rounded, 'Suspended', _n('suspended'), AppColors.negativeRed),
                        const SizedBox(width: 10),
                        _Stat(Icons.shield_outlined, 'Admins', _n('admins'), AppColors.goldDeep),
                      ]),
                      const SizedBox(height: 20),
                      _NavTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Users',
                        subtitle: 'View details, suspend, promote or delete accounts',
                        onTap: () => _open(const AdminUsersScreen()),
                      ),
                      const SizedBox(height: 10),
                      _NavTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Support inbox',
                        subtitle: 'Read and reply to messages from users',
                        badge: (_stats['unreadMessages'] as num?)?.toInt() ?? 0,
                        onTap: () => _open(const AdminInboxScreen()),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    const BoxDecoration(color: AppColors.mintTint, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.forestGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.goldWarm, borderRadius: BorderRadius.circular(12)),
                  child: Text('$badge',
                      style: const TextStyle(
                          color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}
