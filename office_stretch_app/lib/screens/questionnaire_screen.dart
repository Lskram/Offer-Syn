import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../widgets/office_relief_brand_mark.dart';
import '../widgets/office_relief_mascot.dart';
import '../widgets/plan_editor_form.dart';

class QuestionnaireScreen extends StatelessWidget {
  const QuestionnaireScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.questionnaireScreen,
      body: SafeArea(
        child: PlanEditorForm(
          initialSettings: appState.settings,
          includeScheduleSection: true,
          submitLabel: 'สร้างแผนแนะนำ',
          submitKey: AppKeys.questionnaireSubmit,
          topSection: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0864D8),
                  Color(0xFF17B7E3),
                  Color(0xFFB9F32B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OfficeReliefBrandMark(size: 70, showWordmark: true),
                const SizedBox(height: 12),
                const Center(child: OfficeReliefMascot(size: 172)),
                const SizedBox(height: 16),
                Text(
                  'สร้างแผนยืดเส้นเฉพาะของคุณ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'เลือกกลุ่มอาการ ตั้งช่วงเวลาทำงาน และ OfficeRelief จะจัดแผนรวมให้พร้อมใช้งานทันที',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                ),
              ],
            ),
          ),
          onSubmit: (result) async {
            await appState.savePlan(
              profile: result.profile,
              intervalMinutes: result.intervalMinutes,
              activeStart: result.activeStart,
              activeEnd: result.activeEnd,
            );
          },
        ),
      ),
    );
  }
}
