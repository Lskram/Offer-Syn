import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/app_models.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  PainArea? _painArea;
  PainLevel? _painLevel;
  WorkHours? _workHours;
  StretchHabit? _stretchHabit;

  bool get _isComplete =>
      _painArea != null &&
      _painLevel != null &&
      _workHours != null &&
      _stretchHabit != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.questionnaireScreen,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F6F78), Color(0xFF5FA39C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สร้างโปรแกรมพักยืดของคุณ',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MVP นี้รองรับ 3 กลุ่มอาการหลัก: คอ บ่า ไหล่, หลังส่วนบน, และหลังล่าง เพื่อให้เริ่มพัฒนาได้เร็วและตรงกับข้อมูลท่าที่มีอยู่',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _QuestionSection<PainArea>(
              title: 'บริเวณที่ปวดบ่อยที่สุด',
              subtitle: 'เลือกอาการหลักที่อยากให้แอปช่วยจัดโปรแกรมก่อน',
              values: PainArea.values,
              selected: _painArea,
              labelBuilder: (value) => value.label,
              helperBuilder: (value) => value.description,
              optionKeyBuilder: AppKeys.painAreaOption,
              onSelected: (value) => setState(() => _painArea = value),
            ),
            const SizedBox(height: 16),
            _QuestionSection<PainLevel>(
              title: 'ระดับความปวดตอนนี้',
              subtitle: 'ค่านี้ใช้กำหนดรอบแจ้งเตือนเริ่มต้น 30 / 45 / 60 นาที',
              values: PainLevel.values,
              selected: _painLevel,
              labelBuilder: (value) => value.label,
              helperBuilder: (value) => value.frequencyHint,
              optionKeyBuilder: AppKeys.painLevelOption,
              onSelected: (value) => setState(() => _painLevel = value),
            ),
            const SizedBox(height: 16),
            _QuestionSection<WorkHours>(
              title: 'ใช้คอมพิวเตอร์วันละกี่ชั่วโมง',
              subtitle: 'ช่วยประเมินว่าควรเน้นเตือนถี่แค่ไหนในวันทำงาน',
              values: WorkHours.values,
              selected: _workHours,
              labelBuilder: (value) => value.label,
              optionKeyBuilder: AppKeys.workHoursOption,
              onSelected: (value) => setState(() => _workHours = value),
            ),
            const SizedBox(height: 16),
            _QuestionSection<StretchHabit>(
              title: 'ปกติยืดเส้นหรือออกกำลังกายบ่อยแค่ไหน',
              subtitle: 'ใช้เพื่อปรับโทนคำแนะนำและวางระดับความยากในอนาคต',
              values: StretchHabit.values,
              selected: _stretchHabit,
              labelBuilder: (value) => value.label,
              optionKeyBuilder: AppKeys.stretchHabitOption,
              onSelected: (value) => setState(() => _stretchHabit = value),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'หมายเหตุ: แอปนี้เป็นเครื่องมือดูแลตนเองเบื้องต้น ไม่ใช่การวินิจฉัยโรค หากมีอาการร้าว ชา เวียนหัว หรือปวดมากผิดปกติ ควรพบแพทย์หรือนักกายภาพบำบัด',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.72,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Android reminder checklist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ระบบตอนนี้ใช้ local notifications แบบประหยัดแบต จึงแจ้งเตือนได้ตอนจอดำหรือกำลังใช้แอปอื่น แต่เวลาอาจคลาดเล็กน้อยบนบางเครื่อง',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    const _ChecklistItem(
                      text: 'อนุญาต notification ให้แอปก่อนเริ่มใช้งานจริง',
                    ),
                    const _ChecklistItem(
                      text:
                          'ตั้ง Battery เป็น Unrestricted หรือปิดการจำกัดแบตของผู้ผลิตเครื่องถ้าต้องการเตือนสม่ำเสมอ',
                    ),
                    const _ChecklistItem(
                      text:
                          'ถ้าเครื่องเปิด Do Not Disturb หรือปิดเสียง ระบบอาจเตือนแบบไม่มีเสียง',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: AppKeys.questionnaireSubmit,
              onPressed: _isComplete ? _submit : null,
              icon: const Icon(Icons.auto_awesome),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('สร้างโปรแกรมแนะนำ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    widget.appState.completeQuestionnaire(
      UserProfile(
        painArea: _painArea!,
        painLevel: _painLevel!,
        workHours: _workHours!,
        stretchHabit: _stretchHabit!,
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _QuestionSection<T> extends StatelessWidget {
  const _QuestionSection({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.helperBuilder,
    this.optionKeyBuilder,
  });

  final String title;
  final String subtitle;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelBuilder;
  final String Function(T value)? helperBuilder;
  final Key Function(T value)? optionKeyBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: values.map((value) {
                return ChoiceChip(
                  key: optionKeyBuilder?.call(value),
                  label: Text(labelBuilder(value)),
                  selected: value == selected,
                  onSelected: (_) => onSelected(value),
                );
              }).toList(),
            ),
            if (selected != null && helperBuilder != null) ...[
              const SizedBox(height: 14),
              Text(
                helperBuilder!(selected as T),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
