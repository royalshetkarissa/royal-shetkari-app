import 'package:flutter/material.dart';
import '../widgets/royal_app_bar.dart';
import '../localization/app_localizations.dart';

class OrganicTipsScreen extends StatelessWidget {
  const OrganicTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: RoyalAppBar(
        title: context.translate('organic_tips_title'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            stops: [0.0, 0.25],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildIntroductionCard(context),
            const SizedBox(height: 16),
            _buildTipCard(
              context,
              titleKey: 'tip1_title',
              icon: Icons.opacity,
              color: Colors.amber[800]!,
              stepKeys: [
                'tip1_step1',
                'tip1_step2',
                'tip1_step3',
                'tip1_step4',
                'tip1_step5',
                'tip1_step6',
                'tip1_step7',
              ],
              benefitKeys: [
                'tip1_benefit1',
                'tip1_benefit2',
              ],
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              context,
              titleKey: 'tip2_title',
              icon: Icons.eco,
              color: Colors.green[800]!,
              stepKeys: [
                'tip2_step1',
                'tip2_step2',
                'tip2_step3',
                'tip2_step4',
                'tip2_step5',
                'tip2_step6',
                'tip2_step7',
                'tip2_step8',
              ],
              benefitKeys: [
                'tip2_benefit1',
                'tip2_benefit2',
              ],
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              context,
              titleKey: 'tip3_title',
              icon: Icons.layers,
              color: Colors.brown[700]!,
              stepKeys: [
                'tip3_step1',
                'tip3_step2',
                'tip3_step3',
                'tip3_step4',
                'tip3_step5',
                'tip3_step6',
              ],
              benefitKeys: [
                'tip3_benefit1',
                'tip3_benefit2',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.translate('toxic_free_farming'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.translate('toxic_free_farming_desc'),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String titleKey,
    required IconData icon,
    required Color color,
    required List<String> stepKeys,
    required List<String> benefitKeys,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate(titleKey),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.translate('step_by_step_method')}:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ...stepKeys.asMap().entries.map((entry) {
                  int idx = entry.key + 1;
                  String key = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            '$idx',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.translate(key),
                            style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 24),
                Text(
                  '${context.translate('key_benefits')}:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green),
                ),
                const SizedBox(height: 6),
                ...benefitKeys.map((key) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.translate(key),
                              style: const TextStyle(
                                  fontSize: 12.5, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
