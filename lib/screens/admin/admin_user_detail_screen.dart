import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/screens/home/widgets/user_avatar.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/utils/toast.dart';
import 'admin_inbox_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final int userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _user == null;
      _error = null;
    });
    try {
      final d = await ApiClient.getAdminUser(widget.userId);
      if (mounted) setState(() => _user = d['user'] as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String title, String body, String label, {bool danger = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: danger ? TextButton.styleFrom(foregroundColor: AppColors.negativeRed) : null,
            child: Text(label),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _run(String action, String doneMessage, {bool leaveAfter = false}) async {
    setState(() => _busy = true);
    try {
      await ApiClient.adminUserAction(widget.userId, action);
      if (!mounted) return;
      toast(context, doneMessage);
      if (leaveAfter) {
        Navigator.pop(context);
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(Object? v) {
    final t = DateTime.tryParse('$v')?.toLocal();
    if (t == null) return '—';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${m[t.month - 1]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('User details')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
    }
    final u = _user;
    if (u == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error ?? 'User not found.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GoldButton(label: 'Try again', onPressed: _load),
          ]),
        ),
      );
    }

    final name = ((u['name'] as String?)?.trim().isNotEmpty ?? false) ? u['name'] as String : '${u['email']}';
    final suspended = u['status'] == 'SUSPENDED';
    final isAdmin = u['role'] == 'ADMIN';
    final isPrimaryAdmin = u['primaryAdmin'] == true || u['primaryAdmin'] == 1;
    final canManageAdmins = u['canManageAdmins'] == true;
    final isSelf = u['isSelf'] == true;
    final verified = u['emailVerified'];

    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.brandBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                UserAvatar(avatar: u['avatar'] as String?, radius: 42),
                const SizedBox(height: 10),
                Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                Text('${u['email']}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _Badge(isAdmin ? 'Admin' : 'User', AppColors.goldLight),
                    if (isPrimaryAdmin)
                      const _Badge('Primary admin', AppColors.goldLight),
                    _Badge(suspended ? 'Suspended' : 'Active',
                        suspended ? const Color(0xFFFCA5A5) : AppColors.positiveMint),
                    if (isSelf) const _Badge('You', Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card([
            _row(Icons.public_rounded, 'Country',
                (u['countryName'] as String?)?.isNotEmpty ?? false ? u['countryName'] as String : '—'),
            _row(Icons.attach_money_rounded, 'Home currency', '${u['baseCurrency'] ?? '—'}'),
            _row(Icons.verified_outlined, 'Email',
                verified == null ? 'Unknown' : (verified == true ? 'Verified' : 'Not verified')),
            _row(Icons.event_outlined, 'Joined', _date(u['createdAt'])),
            _row(Icons.login_rounded, 'Last sign-in', _date(u['lastSignIn'])),
          ]),
          const SizedBox(height: 12),
          _card([
            _row(Icons.currency_exchange_rounded, 'Saved conversions', '${u['conversions']}'),
            _row(Icons.notifications_active_outlined, 'Active rate alerts', '${u['activeAlerts']}'),
            _row(Icons.chat_bubble_outline_rounded, 'Support messages', '${u['messages']}'),
            _row(Icons.phone_android_rounded, 'Devices registered for push', '${u['devices']}'),
            _row(Icons.tune_rounded, 'Push / rate alerts',
                '${u['pushEnabled'] == true ? 'On' : 'Off'} / ${u['alertsEnabled'] == true ? 'On' : 'Off'}'),
          ]),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminChatScreen(userId: widget.userId, title: name)),
            ),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Message user'),
          ),
          const SizedBox(height: 12),
          if (isSelf)
            const Text('This is your own account, so account actions are disabled.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted))
          else if (isPrimaryAdmin)
            const Text('This is the protected primary admin account.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted))
          else ...[
            if (canManageAdmins) ...[
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        if (isAdmin) {
                          if (await _confirm('Remove admin access?',
                              '$name will lose access to the admin tools.', 'Remove')) {
                            _run('demote', 'Admin access removed.');
                          }
                        } else if (await _confirm('Promote to admin?',
                            '$name will be able to use the admin dashboard and manage regular accounts.',
                            'Promote')) {
                          _run('promote', '$name is now an admin.');
                        }
                      },
                icon: Icon(isAdmin ? Icons.shield_outlined : Icons.shield_rounded),
                label: Text(isAdmin ? 'Remove admin access' : 'Promote to admin'),
              ),
              const SizedBox(height: 10),
            ],
            if (canManageAdmins || !isAdmin) OutlinedButton.icon(
              onPressed: _busy || (isAdmin && !suspended)
                  ? null
                  : () async {
                      if (suspended) {
                        if (await _confirm('Reactivate account?', '$name will be able to sign in again.', 'Reactivate')) {
                          _run('unsuspend', 'Account reactivated.');
                        }
                      } else if (await _confirm('Suspend account?',
                          '$name will be signed out and unable to sign in until reactivated.', 'Suspend',
                          danger: true)) {
                        _run('suspend', 'Account suspended.');
                      }
                    },
              icon: Icon(suspended ? Icons.lock_open_rounded : Icons.block_rounded),
              label: Text(suspended ? 'Reactivate account' : 'Suspend account'),
            ),
            if (canManageAdmins || !isAdmin) const SizedBox(height: 10),
            if (canManageAdmins || !isAdmin) OutlinedButton.icon(
              onPressed: _busy || isAdmin
                  ? null
                  : () async {
                      if (await _confirm('Delete account permanently?',
                          'This removes $name and all their saved conversions, alerts and messages. It cannot be undone.',
                          'Delete', danger: true)) {
                        _run('delete', 'Account deleted.', leaveAfter: true);
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.negativeRed,
                side: BorderSide(color: isAdmin ? AppColors.borderSlate : AppColors.negativeRed),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete account'),
            ),
            if (isAdmin && !canManageAdmins)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Only the primary admin can change this admin account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              ),
            if (isAdmin && canManageAdmins)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Remove admin access first to suspend or delete this account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _card(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              rows[i],
            ],
          ],
        ),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: AppColors.forestGreen, size: 21),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
            ),
            Expanded(
              flex: 2,
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}
