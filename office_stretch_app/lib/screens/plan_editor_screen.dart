import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../widgets/plan_editor_form.dart';

class PlanEditorScreen extends StatelessWidget {
  const PlanEditorScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขแผนหลัก')),
      body: SafeArea(
        child: PlanEditorForm(
          initialProfile: appState.profile,
          initialSettings: appState.settings,
          includeScheduleSection: true,
          submitLabel: 'บันทึกแผนหลัก',
          submitKey: AppKeys.planEditorSave,
          onSubmit: (result) async {
            await appState.savePlan(
              profile: result.profile,
              intervalMinutes: result.intervalMinutes,
              activeStart: result.activeStart,
              activeEnd: result.activeEnd,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
