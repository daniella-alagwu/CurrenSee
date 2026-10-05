import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
      appBar: AppBar(title: const Text('About us')),
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
                  child: const Icon(Icons.attach_money_rounded,
                      size: 44, color: AppColors.emeraldDeep),
                ),
                const SizedBox(height: 12),
                const Text('CurrenSee',
                    style: TextStyle(
                        color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w800)),
                const Text('Better rates. Brighter moves.',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                const Text('Version 1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          block('Our mission',
              'CurrenSee makes checking and converting currencies simple. Whether you are planning a trip, paying an invoice abroad or just curious, you get a clear answer in seconds.'),
          block('What you can do',
              'Convert between major world currencies, follow 7-day rate trends, save the conversions you use often and set your own default currency pair.'),
          block('Where the rates come from',
              'Rates are European Central Bank reference rates, published each working day. They are indicative and may differ from the rate a bank or exchange offers.'),
          block('Your data',
              'Your account is protected with Firebase Authentication. We store your profile, preferences and saved conversions so they follow you across devices.'),
        ],
      ),
    );
  }
}