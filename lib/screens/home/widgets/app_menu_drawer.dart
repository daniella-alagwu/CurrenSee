import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/screens/menu/about_screen.dart';
import 'package:currensee/screens/menu/contact_screen.dart';
import 'package:currensee/screens/menu/profile_settings_screen.dart';
import 'package:currensee/screens/menu/transaction_limits_screen.dart';
import 'package:currensee/services/user_store.dart';
import 'user_avatar.dart';

/// Slides in from the right (used as Scaffold.endDrawer).
class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  Widget _item(BuildContext context, IconData icon, String label, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: AppColors.forestGreen),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: () {
        final nav = Navigator.of(context);
        nav.pop(); // close the drawer
        nav.push(MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = UserStore.instance;
    return Drawer(
      backgroundColor: AppColors.white,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.brandBackground),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(avatar: store.avatar, radius: 32),
                  const SizedBox(height: 12),
                  Text(store.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(store.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _item(context, Icons.manage_accounts_outlined, 'Profile settings',
                const ProfileSettingsScreen()),
            _item(context, Icons.support_agent_rounded, 'Contact', const ContactScreen()),
            _item(context, Icons.info_outline_rounded, 'About us', const AboutScreen()),
            _item(context, Icons.speed_rounded, 'Transaction limits',
                const TransactionLimitsScreen()),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.negativeRed),
              title: const Text('Log out',
                  style: TextStyle(color: AppColors.negativeRed, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.of(context).pop();
                store.signOut();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}