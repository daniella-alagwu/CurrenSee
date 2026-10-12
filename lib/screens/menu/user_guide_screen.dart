import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(body,
                  style: const TextStyle(color: AppColors.textDark, height: 1.5, fontSize: 14.5)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('User guide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                      gradient: AppColors.goldMetallic, shape: BoxShape.circle),
                  child: const Icon(Icons.menu_book_rounded,
                      size: 44, color: AppColors.emeraldDeep),
                ),
                const SizedBox(height: 12),
                const Text('CurrenSee User Guide',
                    style: TextStyle(
                        color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Learn how to make the most of CurrenSee',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          block('Getting Started',
              'Welcome to CurrenSee! This app helps you convert currencies quickly and easily. Sign in with your account to save your preferences and access features across devices.'),
          block('Converting Currencies',
              'On the home screen, select the currency you want to convert from and the currency you want to convert to. Enter the amount, and the app will instantly show you the converted value. The round green button in the middle of the two currencies can be clicked to swap currencies and compare.'),
          block('Viewing Rate Trends',
              'Tap on a currency pair to see a 7-day rate history chart. This helps you understand how exchange rates have been moving over the past week, so you can make better timing decisions.'),
          block('Saving Conversions',
              'If you frequently convert between specific currencies, save that conversion for quick access. Tap the save button on any conversion to add it to your favorites.'),
          block('Setting Your Preferences',
              'Go to Profile settings to choose your default currency pair and customize the app to match your needs. Your settings are saved and sync across all your devices.'),
          block('Transaction Limits',
              'Check the Transaction limits section to understand any restrictions on conversions. This ensures you stay within allowed limits for your account type.'),
          block('Getting Help',
              'If you have questions or run into issues, visit the Contact section to reach out to our support team. We are here to help you get the most out of CurrenSee.'),
        ],
      ),
    );
  }
}
