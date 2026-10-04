import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/screens/home/widgets/chat_view.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSlate,
        appBar: AppBar(
          title: const Text('Contact'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Chat with support'),
            Tab(text: 'Contact info'),
          ]),
        ),
        body: TabBarView(
          children: [
            ChatView(
              mySender: 'USER',
              load: ApiClient.getMessages,
              send: ApiClient.sendMessage,
              emptyText: 'Send us a message and our support team will reply here.',
            ),
            const _ContactInfo(),
          ],
        ),
      ),
    );
  }
}

// Sample details — replace with the client's real ones before launch.
class _ContactInfo extends StatelessWidget {
  const _ContactInfo();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String title, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    const BoxDecoration(color: AppColors.mintTint, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.forestGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            color: AppColors.textDark, fontWeight: FontWeight.w700, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Column(
            children: [
              row(Icons.mail_outline_rounded, 'Email', 'support@currensee.app'),
              const Divider(height: 1),
              row(Icons.phone_outlined, 'Phone', '+1 (555) 013-2468'),
              const Divider(height: 1),
              row(Icons.chat_bubble_outline_rounded, 'WhatsApp', '+1 (555) 013-9902'),
              const Divider(height: 1),
              row(Icons.schedule_rounded, 'Support hours', 'Monday to Friday, 9:00 AM – 6:00 PM'),
              const Divider(height: 1),
              row(Icons.location_on_outlined, 'Office',
                  '221 Market Street, Suite 400\nSan Francisco, CA 94105'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'For the fastest answer, use the Chat tab. Replies usually arrive within one working day.',
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
      ],
    );
  }
}
