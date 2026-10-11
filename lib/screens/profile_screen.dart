import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/services/user_store.dart';
import 'package:currensee/screens/home/widgets/user_avatar.dart';
import 'menu/profile_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onOpenMenu});

  final VoidCallback onOpenMenu;

  String _date(DateTime? d) {
    if (d == null) return '—';

    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStore.instance;
    final fbUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final code = RatesService.startingBase(store.baseCurrency);
          final info = RatesService.info(code);
          final verified = fbUser?.emailVerified ?? false;

          return RefreshIndicator(
            color: AppColors.forestGreen,
            onRefresh: () => store.load(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      UserAvatar(
                        avatar: store.avatar,
                        radius: 46,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        store.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (store.error != null && !store.loaded) ...[
                  const SizedBox(height: 12),
                  Text(
                    store.error!,
                    style: const TextStyle(
                      color: AppColors.negativeRed,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSlate),
                  ),
                  child: Column(
                    children: [
                      _row(
                        Icons.person_outline_rounded,
                        'Name',
                        store.displayName,
                      ),
                      const Divider(height: 1),
                      _row(
                        Icons.mail_outline_rounded,
                        'Email',
                        store.email,
                      ),
                      const Divider(height: 1),
                      _row(
                        Icons.public_rounded,
                        'Country',
                        (store.countryName?.isNotEmpty ?? false)
                            ? store.countryName!
                            : '—',
                      ),
                      const Divider(height: 1),
                      _row(
                        Icons.attach_money_rounded,
                        'Home currency',
                        '${info.flag}  $code · ${info.name}',
                      ),
                      const Divider(height: 1),
                      _row(
                        Icons.verified_outlined,
                        'Email status',
                        verified ? 'Verified' : 'Not verified',
                      ),
                      const Divider(height: 1),
                      _row(
                        Icons.event_outlined,
                        'Member since',
                        _date(fbUser?.metadata.creationTime),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GoldButton(
                  label: 'Edit profile',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.forestGreen,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}
