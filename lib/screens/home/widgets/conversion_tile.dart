import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/utils/format.dart';


class ConversionTile extends StatelessWidget {
  const ConversionTile({super.key, required this.item, this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final from = '${item['fromCode'] ?? ''}';
    final to = '${item['toCode'] ?? ''}';
    final amount = double.tryParse('${item['amount']}');
    final result = double.tryParse('${item['result']}');
    final rate = trimZeros('${item['rateUsed'] ?? ''}');
    final when = DateTime.tryParse('${item['createdAt']}')?.toLocal();

    final amountText =
        amount == null ? '${item['amount']}' : formatNumber(amount, decimals: decimalsFor(from));
    final resultText =
        result == null ? '${item['result']}' : formatNumber(result, decimals: decimalsFor(to));
    final detail = when == null ? '1 $from = $rate $to' : '1 $from = $rate $to  ·  ${shortDateTime(when)}';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: const CircleAvatar(
        backgroundColor: AppColors.mintTint,
        child: Icon(Icons.swap_horiz_rounded, color: AppColors.forestGreen),
      ),
      title: Text(
        '$amountText $from  →  $resultText $to',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        detail,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.replay_rounded, size: 18, color: AppColors.textMuted),
    );
  }
}
