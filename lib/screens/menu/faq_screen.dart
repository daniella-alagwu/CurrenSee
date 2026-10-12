import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'What is CurrenSee?',
        'answer': 'CurrenSee is a currency conversion app that helps you check exchange rates and convert between major world currencies quickly and easily.',
        'icon': Icons.currency_exchange_rounded,
      },
      {
        'question': 'How accurate are the exchange rates?',
        'answer': 'Our rates are daily reference rates from central banks and official sources. They are indicative and may differ slightly from the rate a bank or exchange offers.',
        'icon': Icons.graphic_eq_rounded,
      },
      {
        'question': 'Which currencies are supported?',
        'answer': 'CurrenSee supports all major world currencies including USD, EUR, GBP, JPY, CAD, AUD, CHF, and many more. You can search and select from the full list in the app.',
        'icon': Icons.public_rounded,
      },
      {
        'question': 'Do I need an account to use the app?',
        'answer': 'You can use basic conversion features without an account. However, signing in allows you to save your preferences, save frequently used conversions, and access your data across devices.',
        'icon': Icons.person_outline_rounded,
      },
      {
        'question': 'How do I save a conversion?',
        'answer': 'After performing a conversion, tap the save button to add it to your favorites. You can access your saved conversions quickly from the home screen.',
        'icon': Icons.favorite_border_rounded,
      },
      {
        'question': 'Can I view historical rate trends?',
        'answer': 'Yes! Tap on any currency pair to view a 7-day rate history chart. This helps you understand how exchange rates have been moving over the past week.',
        'icon': Icons.show_chart_rounded,
      },
      {
        'question': 'How do I change my default currency?',
        'answer': 'Go to Profile settings and select your preferred default currency pair. This will be used as your starting point each time you open the app.',
        'icon': Icons.settings_rounded,
      },
      {
        'question': 'Is my data secure?',
        'answer': 'Yes. Your account is protected with Firebase Authentication. We store your profile, preferences and saved conversions securely so they follow you across devices.',
        'icon': Icons.security_rounded,
      },
      {
        'question': 'What are transaction limits?',
        'answer': 'Transaction limits vary based on your account type. You can check the Transaction limits section in the menu to understand any restrictions on conversions for your account.',
        'icon': Icons.speed_rounded,
      },
      {
        'question': 'How do I contact support?',
        'answer': 'If you have questions or run into issues, visit the Contact section in the menu to reach out to our support team. We are here to help you.',
        'icon': Icons.support_agent_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: AppColors.surfaceSlate,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldMetallic,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      size: 48, color: AppColors.emeraldDeep),
                ),
                const SizedBox(height: 16),
                const Text('Got Questions?',
                    style: TextStyle(
                        color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('We\'ve got answers! 🎉',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Tap any question to expand',
                    style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...faqs.map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.forestGreen.withOpacity(0.1)),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.forestGreen.withOpacity(0.1),
                            AppColors.emeraldDeep.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(faq['icon'] as IconData,
                          color: AppColors.forestGreen, size: 22),
                    ),
                    title: Text(
                      faq['question'] as String,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    iconColor: AppColors.forestGreen,
                    collapsedIconColor: AppColors.textMuted,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Text(
                          faq['answer'] as String,
                          style: TextStyle(
                            color: AppColors.textDark.withOpacity(0.85),
                            height: 1.6,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.forestGreen.withOpacity(0.1),
                    AppColors.emeraldDeep.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Still need help? Check the Contact section!',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
