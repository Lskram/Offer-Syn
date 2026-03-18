import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/app_models.dart';
import '../widgets/office_relief_brand_mark.dart';
import '../widgets/office_relief_mascot.dart';

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
                    'OfficeRelief จะใช้จุดที่ปวด ระดับอาการ และพฤติกรรมการทำงาน เพื่อจัดโปรแกรมพักยืดเส้นที่เหมาะกับคุณที่สุดในเวอร์ชันนี้',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _QuestionSection<PainArea>(
              title: 'บริเวณที่ปวดบ่อยที่สุด',
              subtitle: 'เลือกจุดหลักที่อยากให้แอปช่วยจัดโปรแกรมก่อน',
              values: PainArea.values,
              selected: _painArea,
              labelBuilder: (value) => value.label,
              helperBuilder: (value) => value.description,
              optionKeyBuilder: AppKeys.painAreaOption,
              onSelected: (value) => setState(() => _painArea = value),
            ),
            const SizedBox(height: 16),
            _QuestionSection<PainLevel>(
              title: 'ระดับอาการตอนนี้',
              subtitle: 'ค่านี้จะใช้กำหนดรอบเตือนเริ่มต้น 30 / 45 / 60 นาที',
              values: PainLevel.values,
              selected: _painLevel,
              labelBuilder: (value) => value.label,
              helperBuilder: (value) => value.frequencyHint,
              optionKeyBuilder: AppKeys.painLevelOption,
              onSelected: (value) => setState(() => _painLevel = value),
            ),
            const SizedBox(height: 16),
            _QuestionSection<WorkHours>(
              title: 'ใช้คอมต่อวันประมาณกี่ชั่วโมง',
              subtitle:
                  'ช่วยให้ระบบสรุประดับความเสี่ยงจากการนั่งทำงานได้ชัดขึ้น',
              values: WorkHours.values,
              selected: _workHours,
              labelBuilder: (value) => value.label,
              optionKeyBuilder: AppKeys.workHoursOption,
              onSelected: (value) => setState(() => _workHours = value),
            ),
            const SizedBox(height: 16),
            _QuestionSection<StretchHabit>(
              title: 'ปกติยืดเส้นหรือเปลี่ยนอิริยาบถบ่อยแค่ไหน',
              subtitle: 'ใช้เพื่อปรับคำแนะนำและโทนการดูแลในแอป',
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
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.74),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Android reminder checklist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'OfficeRelief ใช้ local notifications จึงแจ้งเตือนได้ตอนจอดำหรือเปิดแอปอื่นอยู่ แต่เวลาอาจคลาดเคลื่อนได้เล็กน้อยบนบางเครื่อง',
                    ),
                    SizedBox(height: 12),
                    _ChecklistItem(
                      text: 'อนุญาต notification ให้แอปก่อนใช้งานจริง',
                    ),
                    _ChecklistItem(
                      text:
                          'ตั้ง Battery เป็น Unrestricted ถ้าต้องการการเตือนสม่ำเสมอ',
                    ),
                    _ChecklistItem(
                      text:
                          'ถ้าเปิด Do Not Disturb หรือปิดเสียงเครื่อง การเตือนอาจไม่มีเสียงหรือสั่น',
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
                child: Text('สร้างแผนแนะนำ'),
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
                fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
