import 'package:countries_utils/countries_data.dart' as country_data;
import 'package:currency_picker/currency_picker.dart' as currency_picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';

//once for people who signed up with socal login... to collect their data like country and all.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  Map<String, dynamic>? _country;
  String? _currencyCode;
  String? _currencyName;
  String? _currencySymbol;

  void _selectCountry(Map<String, dynamic> country) {
    setState(() {
      _country = country;
      final currencies = country['currencies'] as List<dynamic>? ?? const [];
      if (currencies.isNotEmpty) {
        final c = currencies.first as Map<String, dynamic>;
        _currencyCode = c['code'] as String?;
        _currencyName = c['name'] as String?;
        _currencySymbol = c['symbol'] as String?;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_country == null || _currencyCode == null) return;
    setState(() => _saving = true);
    try {
      await ApiClient.registerProfile(
        countryCode: _country!['alpha2Code'] as String? ?? '',
        countryName: _country!['name'] as String? ?? '',
        currencyCode: _currencyCode,
        currencyName: _currencyName,
        currencySymbol: _currencySymbol,
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) showAuthError(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.forestGreen),
        filled: true,
        fillColor: AppColors.surfaceSlate,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final first = (user?.displayName ?? '').trim().split(' ').first;
    return AuthScaffold(
      title: first.isEmpty ? 'Almost there' : 'Welcome, $first',
      subtitle: 'Choose your country and preferred starting currency to finish setting up.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (c) => c['name'] as String? ?? '',
              optionsBuilder: (value) {
                final query = value.text.trim();
                if (query.isEmpty) return <Map<String, dynamic>>[];
                return country_data.countriesData.where((c) {
                  final name = c['name'] as String? ?? '';
                  return name.toLowerCase().contains(query.toLowerCase());
                }).take(10);
              },
              onSelected: _selectCountry,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _decoration('Country', Icons.public),
                  textInputAction: TextInputAction.next,
                  validator: (_) =>
                      _country == null ? 'Choose a country from the suggestions' : null,
                  onChanged: (value) {
                    if (_country != null && value != (_country!['name'] as String?)) {
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
                    width: (MediaQuery.sizeOf(context).width - 96).clamp(220.0, 340.0),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final country = options.elementAt(index);
                        return ListTile(
                          title: Text(country['name'] as String? ?? ''),
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
              validator: (_) => _currencyCode == null ? 'Choose a default currency' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _saving ? null : _chooseCurrency,
                    child: InputDecorator(
                      decoration: _decoration('Default currency', Icons.currency_exchange)
                          .copyWith(errorText: field.errorText),
                      child: Row(children: [
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
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GoldButton(label: 'Continue', isLoading: _saving, onPressed: _save),
            const SizedBox(height: 8),
            Center(
              child: AuthLink(
                label: 'Use a different account',
                onPressed: _saving ? () {} : () => FirebaseAuth.instance.signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}