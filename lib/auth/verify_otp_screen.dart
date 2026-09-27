import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import "../services/api_client.dart";
import 'auth_widgets.dart';


class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.onVerified});

  final Future<void> Function() onVerified;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _codeController = TextEditingController();

  bool _sending = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ApiClient.sendOtp();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ApiClient.verifyOtp(code);
      await widget.onVerified();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Enter your code',
      subtitle: _sending
          ? 'Sending a 6-digit code to your email…'
          : "We've sent a 6-digit code to your email.",
      child: Column(
        children: [
          AuthTextField(
            controller: _codeController,
            label: '6-digit code',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.negativeRed, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 20),
          GoldButton(label: 'Verify', isLoading: _verifying, onPressed: _verify),
          const SizedBox(height: 8),
          AuthLink(
            label: _sending ? 'Sending…' : 'Resend code',
            onPressed: _sending ? () {} : _sendCode,
          ),
        ],
      ),
    );
  }
}
