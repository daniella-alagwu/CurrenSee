import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/screens/notifications_screen.dart';
import 'package:currensee/services/notification_store.dart';
import 'package:currensee/services/user_store.dart';
import 'user_avatar.dart';

/// Notification bell + user profile avatar.
class HeaderActions extends StatelessWidget {
  const HeaderActions({
    super.key,
    this.onOpenMenu,
    this.onOpenProfile,
    this.iconColor = AppColors.textDark,
    this.avatarBackground = AppColors.emeraldBg,
  });

  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenProfile;
  final Color iconColor;
  final Color avatarBackground;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: NotificationStore.instance,
          builder: (context, _) {
            final unread = NotificationStore.instance.unread;

            return IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: iconColor,
                    size: 28,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldWarm,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // User profile avatar.
        ListenableBuilder(
          listenable: UserStore.instance,
          builder: (_, _) {
            return GestureDetector(
              onTap: onOpenProfile ?? onOpenMenu,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 14,
                ),
                child: UserAvatar(
                  avatar: UserStore.instance.avatar,
                  radius: 21,
                  background: avatarBackground,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}