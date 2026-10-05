import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/services/user_store.dart';
import 'package:currensee/utils/format.dart';


class _Limit {
  const _Limit(this.limit, this.used);
  final double limit;
  final double used;
  double get remaining => (limit - used).clamp(0, limit).toDouble();
  double get ratio => limit == 0 ? 0 : (used / limit).clamp(0, 1).toDouble();
}

const _totalInflow = _Limit(50000, 18250);
const _totalOutflow = _Limit(30000, 7400);
const _channels = [
  ('Bank transfer', Icons.account_balance_outlined, _Limit(30000, 12000), _Limit(20000, 5000)),
  ('Card', Icons.credit_card_rounded, _Limit(20000, 6250), _Limit(10000, 2400)),
];
const _perTransaction = 5000.0;
const _daily = 10000.0;

class TransactionLimitsScreen extends StatelessWidget {
  const TransactionLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = RatesService.startingBase(UserStore.instance.baseCurrency);
    final sym = RatesService.info(code).symbol;
    String money(double v) => '$sym${formatNumber(v, decimals: 0)}';

    Widget bar(_Limit l, Color color) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: l.ratio,
            minHeight: 8,
            backgroundColor: AppColors.borderSlate,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        );

    Widget summary(String title, IconData icon, _Limit l, Color color) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              Text(money(l.remaining),
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 30, fontWeight: FontWeight.w800)),
              const Text('remaining', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 12),
              bar(l, color),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Used ${money(l.used)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                  Text('Limit ${money(l.limit)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ],
              ),
            ],
          ),
        );

    Widget channelLine(String label, _Limit l, Color color) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                  Text('${money(l.remaining)} left',
                      style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              bar(l, color),
              const SizedBox(height: 4),
              Text('${money(l.used)} of ${money(l.limit)} used',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('Transaction limits')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.mintTint, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.forestGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Standard tier  ·  limits reset on the 1st of each month',
                      style: TextStyle(color: AppColors.emeraldBg, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          summary('Total inflow', Icons.south_west_rounded, _totalInflow, AppColors.positiveMint),
          const SizedBox(height: 12),
          summary('Total outflow', Icons.north_east_rounded, _totalOutflow, AppColors.goldDeep),
          const SizedBox(height: 12),
          for (final c in _channels) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(c.$2, color: AppColors.forestGreen),
                    const SizedBox(width: 8),
                    Text(c.$1,
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                  ]),
                  channelLine('Inflow', c.$3, AppColors.positiveMint),
                  channelLine('Outflow', c.$4, AppColors.goldDeep),
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Column(
              children: [
                _kv('Per-transaction limit', money(_perTransaction)),
                const Divider(height: 24),
                _kv('Daily limit', money(_daily)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Figures shown are sample data for demonstration.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: AppColors.textMuted)),
          Text(v, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
        ],
      );
}