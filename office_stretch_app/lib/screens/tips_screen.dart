import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        key: AppKeys.tipsScreen,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Tips และหลักการดูแลตัวเอง',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'สรุปจากเอกสารงานวิจัยที่คุณให้มา เพื่อใช้เป็นเนื้อหาเริ่มต้นในแอป',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          ...appState.tips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(tip.summary),
                      const SizedBox(height: 14),
                      ...tip.bullets.map((bullet) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(bullet)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
