import 'package:countries_utils/countries_data.dart' as country_data;
import 'package:currency_picker/currency_picker.dart' as currency_picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  Map<String, dynamic>? _country;
  String? _currencyCode;
  String? _currencyName;
  String? _currencySymbol;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _selectCountry(Map<String, dynamic> country) {
    setState(() {
      _country = country;
      final currencies = country['currencies'] as List<dynamic>? ?? const [];
      if (currencies.isNotEmpty) {
        final defaultCurrency = currencies.first as Map<String, dynamic>;
        _currencyCode = defaultCurrency['code'] as String?;
        _currencyName = defaultCurrency['name'] as String?;
        _currencySymbol = defaultCurrency['symbol'] as String?;
      } else {
        _currencyCode = null;
        _currencyName = null;
        _currencySymbol = null;
      }
    });
  }

  void _chooseCurrency() {
    currency_picker.showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      favorite: const ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'INR'],
      onSelect: (currency) => setState(() {
        _currencyCode = currency.code;
        _currencyName = currency.name;
        _currencySymbol = currency.symbol;
      }),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_country == null || _currencyCode == null) return;

    setState(() => _loading = true);
    try {
     
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final countryCode = _country!['alpha2Code'] as String? ?? '';
      final countryName = _country!['name'] as String? ?? '';
      final currencyCode = _currencyCode!;
      ApiClient.keepPendingSignupProfile(
        firebaseUid: credential.user!.uid,
        countryCode: countryCode,
        countryName: countryName,
        currencyCode: currencyCode,
        currencyName: _currencyName,
        currencySymbol: _currencySymbol,
      );

    
      try {
        await credential.user?.sendEmailVerification();
      } catch (e) {
        if (mounted) showAuthError(context, authErrorMessage(e));
      }

      try {
        await ApiClient.registerProfile(
          countryCode: countryCode,
          countryName: countryName,
          currencyCode: currencyCode,
          currencyName: _currencyName,
          currencySymbol: _currencySymbol,
        );
      } on ApiException {
        // The profile is created again by EmailVerificationGate after verification.
      }

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _pickerDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.forestGreen),
        filled: true,
        fillColor: AppColors.surfaceSlate,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Choose your country and preferred starting currency.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthTextField(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 6) return 'Use at least 6 characters';
                return null;
              },
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                color: AppColors.textMuted,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm password',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v != _password.text ? 'Passwords don\'t match' : null,
            ),
            const SizedBox(height: 16),
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (country) =>
                  country['name'] as String? ?? '',
              optionsBuilder: (value) {
                final query = value.text.trim();
                if (query.isEmpty) return <Map<String, dynamic>>[];
                return country_data.countriesData.where((country) {
                  final name = country['name'] as String? ?? '';
                  return name.toLowerCase().contains(query.toLowerCase());
                }).take(10);
              },
              onSelected: _selectCountry,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _pickerDecoration('Country', Icons.public),
                  textInputAction: TextInputAction.next,
                  validator: (_) => _country == null
                      ? 'Choose a country from the suggestions'
                      : null,
                  onChanged: (value) {
                    if (_country != null &&
                        value != (_country!['name'] as String?)) {
                      setState(() => _country = null);
                    }
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: SizedBox(
                    height: 240,
                    width: (MediaQuery.sizeOf(context).width - 96)
                        .clamp(220.0, 340.0),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final country = options.elementAt(index);
                        return ListTile(
                          title: Text(country['name'] as String? ?? ''),
                          subtitle: Text(
                            (country['currencies'] as List<dynamic>? ?? const [])
                                    .isEmpty
                                ? 'Choose a currency below'
                                : 'Default currency: ${((country['currencies'] as List<dynamic>).first as Map<String, dynamic>)['code']}',
                          ),
                          onTap: () => onSelected(country),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FormField<String>(
              validator: (_) => _currencyCode == null
                  ? 'Choose a default currency'
                  : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _loading ? null : _chooseCurrency,
                    child: InputDecorator(
                      decoration: _pickerDecoration(
                        'Default currency',
                        Icons.currency_exchange,
                      ).copyWith(errorText: field.errorText),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currencyCode == null
                                  ? 'Select a currency'
                                  : '${_currencyName ?? _currencyCode} ($_currencyCode)',
                              style: TextStyle(
                                color: _currencyCode == null
                                    ? AppColors.textMuted
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          const Icon(Icons.search, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  if (field.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: AppColors.negativeRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GoldButton(
              label: 'Create account',
              isLoading: _loading,
              onPressed: _register,
            ),
            const SizedBox(height: 8),
            Center(
              child: AuthLink(
                label: 'Already have an account? Log in',
                onPressed: _loading ? () {} : () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
