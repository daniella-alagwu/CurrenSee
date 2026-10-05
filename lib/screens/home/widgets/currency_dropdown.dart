import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/rates_service.dart';

class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({super.key, required this.value, required this.onChanged, this.label});

  final String value;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          style: const TextStyle(
              color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
          items: [
            for (final code in RatesService.supported)
              DropdownMenuItem(
                value: code,
                child: Text('${RatesService.info(code).flag}  $code'),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
    if (label == null) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        box,
      ],
    );
  }
}