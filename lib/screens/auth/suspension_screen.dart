
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';

class SuspensionScreen extends StatefulWidget {
  const SuspensionScreen({super.key});

  @override
  State<SuspensionScreen> createState() => _SuspensionScreenState();
}

class _SuspensionScreenState extends State<SuspensionScreen> {
  final _appealController = TextEditingController();

  List<Map<String, dynamic>> _messages = [];
  bool _loadingMessages = true;
  bool _submitting = false;
  bool _appealSubmitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _appealController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiClient.getMessages();

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _loadingMessages = false;
        _appealSubmitted = messages.any(
          (message) =>
              message['tag'] == 'ACCOUNT_SUSPENSION_APPEAL',
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingMessages = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _submitAppeal() async {
    final body = _appealController.text.trim();

    if (body.isEmpty) {
      _showMessage('Please explain why you are appealing.');
      return;
    }

    if (body.length > 1000) {
      _showMessage('Your appeal must not exceed 1000 characters.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ApiClient.submitSuspensionAppeal(body);

      if (!mounted) return;

      _appealController.clear();

      setState(() {
        _appealSubmitted = true;
      });

      await _loadMessages();

      if (!mounted) return;

      _showMessage('Your appeal has been sent to the administrator.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not submit your appeal: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Account suspension'),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gpp_bad_outlined,
                      color: Colors.deepOrange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your account is suspended',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'An administrator has suspended access to your '
                    'CurrenSee account. If you believe this decision '
                    'was made in error, you can submit an appeal below '
                    'for the administrator to review.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _appealSubmitted
                                ? 'Your appeal has been submitted. '
                                    'You can review your support conversation below.'
                                : 'Your account remains restricted while '
                                    'the administrator reviews your appeal.',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submit an appeal',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explain your situation clearly. Your message will '
                    'be sent to the CurrenSee administrator.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _appealController,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1000,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      hintText: 'Write your appeal here...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: AppColors.surfaceSlate,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submitAppeal,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _submitting ? 'Submitting...' : 'Submit appeal',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support conversation',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingMessages)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AppColors.forestGreen,
                        ),
                      ),
                    )
                  else if (_messages.isEmpty)
                    const Text(
                      'Your appeal and any administrator replies will '
                      'appear here.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    )
                  else
                    ..._messages.map((message) {
                      final fromAdmin = message['sender'] == 'ADMIN';
                      final isAppeal = message['tag'] ==
                          'ACCOUNT_SUSPENSION_APPEAL';

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: fromAdmin
                              ? AppColors.emeraldBg
                              : AppColors.surfaceSlate,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromAdmin
                                  ? 'CurrenSee Support'
                                  : 'You',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (isAppeal) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'ACCOUNT SUSPENSION APPEAL',
                                style: TextStyle(
                                  color: AppColors.forestGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${message['body'] ?? ''}',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: _loadMessages,
                      child: const Text('Retry loading messages'),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _loadingMessages ? null : _loadMessages,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh conversation'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}