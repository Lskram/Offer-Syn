import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../data/exercise_catalog.dart';
import '../models/app_models.dart';

const _chipSelectedColor = Color(0xFF0F5FC9);
const _chipSelectedTextColor = Colors.white;
const _chipUnselectedTextColor = Color(0xFF082A4B);
const _chipUnselectedBackgroundColor = Color(0xFFF6FBFF);

class PlanEditorResult {
  const PlanEditorResult({
    required this.profile,
    required this.intervalMinutes,
    required this.activeStart,
    required this.activeEnd,
  });

  final UserProfile profile;
  final int intervalMinutes;
  final TimeOfDay activeStart;
  final TimeOfDay activeEnd;
}

class PlanEditorForm extends StatefulWidget {
  const PlanEditorForm({
    super.key,
    required this.initialSettings,
    required this.submitLabel,
    required this.submitKey,
    required this.onSubmit,
    this.initialProfile,
    this.topSection,
    this.includeScheduleSection = false,
  });

  final UserProfile? initialProfile;
  final ReminderSettings initialSettings;
  final String submitLabel;
  final Key submitKey;
  final FutureOr<void> Function(PlanEditorResult result) onSubmit;
  final Widget? topSection;
  final bool includeScheduleSection;

  @override
  State<PlanEditorForm> createState() => _PlanEditorFormState();
}

class _PlanEditorFormState extends State<PlanEditorForm> {
  late final Set<PainArea> _selectedAreas;
  late final Map<PainArea, PainLevel?> _painLevels;
  late final Map<PainArea, List<String>> _selectedExerciseIds;
  WorkHours? _workHours;
  StretchHabit? _stretchHabit;
  late int _intervalMinutes;
  late TimeOfDay _activeStart;
  late TimeOfDay _activeEnd;
  bool _isSaving = false;

  bool get _isComplete =>
      _selectedAreas.isNotEmpty &&
      _selectedAreas.every((area) => _painLevels[area] != null) &&
      _workHours != null &&
      _stretchHabit != null;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _selectedAreas = profile?.painSelections.map((entry) => entry.area).toSet() ??
        <PainArea>{};
    _painLevels = {
      for (final area in PainArea.values)
        area: profile?.painSelections
            .where((entry) => entry.area == area)
            .map((entry) => entry.level)
            .cast<PainLevel?>()
            .firstWhere((entry) => true, orElse: () => null),
    };
    _selectedExerciseIds = {
      for (final area in PainArea.values)
        area: profile?.painSelections
                .where((entry) => entry.area == area)
                .map((entry) => entry.selectedExerciseIds)
                .cast<List<String>>()
                .firstWhere((entry) => true, orElse: () => const <String>[]) ??
            const <String>[],
    };
    _workHours = profile?.workHours;
    _stretchHabit = profile?.stretchHabit;
    _intervalMinutes = widget.initialSettings.intervalMinutes;
    _activeStart = widget.initialSettings.activeStart;
    _activeEnd = widget.initialSettings.activeEnd;

    for (final area in _selectedAreas) {
      _normalizeAreaSelection(area);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.topSection != null) ...[
          widget.topSection!,
          const SizedBox(height: 20),
        ],
        _SectionCard(
          title: 'เลือกกลุ่มที่ปวด',
          subtitle: 'เลือกได้ 1-3 กลุ่ม และแต่ละกลุ่มจะมีระดับความปวดกับชุดท่าของตัวเอง',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: PainArea.values.map((area) {
              final isSelected = _selectedAreas.contains(area);
              return FilterChip(
                key: AppKeys.painAreaOption(area),
                label: Text(area.label),
                labelStyle: TextStyle(
                  color: isSelected
                      ? _chipSelectedTextColor
                      : _chipUnselectedTextColor,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: _chipUnselectedBackgroundColor,
                selectedColor: _chipSelectedColor,
                checkmarkColor: _chipSelectedTextColor,
                side: const BorderSide(color: Color(0xFF0F5FC9)),
                selected: isSelected,
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selectedAreas.add(area);
                    _painLevels[area] ??= PainLevel.low;
                    _normalizeAreaSelection(area);
                  } else {
                    _selectedAreas.remove(area);
                    _selectedExerciseIds[area] = const <String>[];
                  }
                }),
              );
            }).toList(growable: false),
          ),
        ),
        const SizedBox(height: 16),
        ..._orderedAreas.map(_buildGroupEditor),
        _SelectionSection<WorkHours>(
          title: 'ใช้คอมต่อวันประมาณกี่ชั่วโมง',
          values: WorkHours.values,
          selected: _workHours,
          labelBuilder: (value) => value.label,
          keyBuilder: AppKeys.workHoursOption,
          onSelected: (value) => setState(() => _workHours = value),
        ),
        const SizedBox(height: 16),
        _SelectionSection<StretchHabit>(
          title: 'ปกติยืดเส้นหรือเปลี่ยนอิริยาบถบ่อยแค่ไหน',
          values: StretchHabit.values,
          selected: _stretchHabit,
          labelBuilder: (value) => value.label,
          keyBuilder: AppKeys.stretchHabitOption,
          onSelected: (value) => setState(() => _stretchHabit = value),
        ),
        if (widget.includeScheduleSection) ...[
          const SizedBox(height: 16),
          _buildScheduleCard(context),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: widget.submitKey,
          onPressed: _isComplete && !_isSaving ? _submit : null,
          icon: const Icon(Icons.save_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(widget.submitLabel),
          ),
        ),
      ],
    );
  }

  List<PainArea> get _orderedAreas => PainArea.values
      .where(_selectedAreas.contains)
      .toList(growable: false);

  Widget _buildGroupEditor(PainArea area) {
    final level = _painLevels[area];
    final availableExercises = level == null
        ? const <Exercise>[]
        : ExerciseCatalog.programFor(area, level).exercises;
    final selectedIds = _selectedExerciseIds[area] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _SectionCard(
        title: area.label,
        subtitle: area.description,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: PainLevel.values.map((value) {
                final isSelected = level == value;
                return ChoiceChip(
                  key: AppKeys.painLevelForAreaOption(area, value),
                  label: Text(value.label),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _chipSelectedTextColor
                        : _chipUnselectedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: _chipUnselectedBackgroundColor,
                  selectedColor: _chipSelectedColor,
                  side: const BorderSide(color: Color(0xFF0F5FC9)),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _painLevels[area] = value;
                    _normalizeAreaSelection(area);
                    _intervalMinutes = _recommendedIntervalMinutes;
                  }),
                );
              }).toList(growable: false),
            ),
            if (level != null) ...[
              const SizedBox(height: 14),
              Text(
                'ท่าของระดับนี้',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (availableExercises.length <= 2)
                ...availableExercises.map(
                  (exercise) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.durationSeconds} วินาที'
                      '${exercise.requiresStanding ? ' • แนะนำให้ลุกขึ้นทำ' : ''}',
                    ),
                  ),
                )
              else ...[
                Text(
                  'เลือกใช้งานได้สูงสุด 2 ท่า และสลับได้ตลอดเวลา',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableExercises.map((exercise) {
                    final isSelected = selectedIds.contains(exercise.id);
                    return FilterChip(
                      key: AppKeys.exerciseOption(area, exercise.id),
                      label: Text(exercise.name),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? _chipSelectedTextColor
                            : _chipUnselectedTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: _chipUnselectedBackgroundColor,
                      selectedColor: _chipSelectedColor,
                      checkmarkColor: _chipSelectedTextColor,
                      side: const BorderSide(color: Color(0xFF0F5FC9)),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        final updated = List<String>.from(selectedIds);
                        if (isSelected) {
                          updated.remove(exercise.id);
                        } else {
                          if (updated.length == 2) {
                            updated.removeAt(0);
                          }
                          updated.add(exercise.id);
                        }
                        _selectedExerciseIds[area] = updated;
                      }),
                    );
                  }).toList(growable: false),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    return _SectionCard(
      title: 'ตั้งเวลาแผนหลัก',
      subtitle: 'แก้ช่วงเวลาและรอบเตือนของแผนนี้ได้จากหน้าเดียว',
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _intervalMinutes,
            decoration: const InputDecoration(labelText: 'รอบแจ้งเตือน'),
            items: const [1, 30, 45, 60, 90, 120]
                .map(
                  (minutes) => DropdownMenuItem<int>(
                    value: minutes,
                    child: Text(
                      minutes == 1
                          ? 'ทุก 1 นาที (สำหรับทดสอบ)'
                          : 'ทุก $minutes นาที',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _intervalMinutes = value);
              }
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            key: AppKeys.scheduleActiveStart,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('เริ่มเตือนตั้งแต่'),
            subtitle: Text(_activeStart.format(context)),
            onTap: () => _pickTime(context, _activeStart, (value) {
              setState(() => _activeStart = value);
            }),
          ),
          ListTile(
            key: AppKeys.scheduleActiveEnd,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.nightlight_outlined),
            title: const Text('หยุดเตือนเวลา'),
            subtitle: Text(_activeEnd.format(context)),
            onTap: () => _pickTime(context, _activeEnd, (value) {
              setState(() => _activeEnd = value);
            }),
          ),
        ],
      ),
    );
  }

  int get _recommendedIntervalMinutes {
    final levels = _orderedAreas
        .map((area) => _painLevels[area])
        .whereType<PainLevel>()
        .toList(growable: false);

    if (levels.isEmpty) {
      return widget.initialSettings.intervalMinutes;
    }

    return levels
        .map((level) => level.reminderIntervalMinutes)
        .reduce((left, right) => left < right ? left : right);
  }

  void _normalizeAreaSelection(PainArea area) {
    final level = _painLevels[area];
    if (level == null) {
      return;
    }

    _selectedExerciseIds[area] = ExerciseCatalog.normalizeSelection(
      area: area,
      level: level,
      selectedExerciseIds: _selectedExerciseIds[area] ?? const <String>[],
    ).selectedExerciseIds;
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initialValue,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialValue,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);

    final profile = UserProfile(
      painSelections: _orderedAreas
          .map(
            (area) => ExerciseCatalog.normalizeSelection(
              area: area,
              level: _painLevels[area]!,
              selectedExerciseIds:
                  _selectedExerciseIds[area] ?? const <String>[],
            ),
          )
          .toList(growable: false),
      workHours: _workHours!,
      stretchHabit: _stretchHabit!,
    );

    try {
      await widget.onSubmit(
        PlanEditorResult(
          profile: profile,
          intervalMinutes: _intervalMinutes,
          activeStart: _activeStart,
          activeEnd: _activeEnd,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectionSection<T> extends StatelessWidget {
  const _SelectionSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.keyBuilder,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelBuilder;
  final Key Function(T value) keyBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: '',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: values.map((value) {
          final isSelected = selected == value;
          return ChoiceChip(
            key: keyBuilder(value),
            label: Text(labelBuilder(value)),
            labelStyle: TextStyle(
              color: isSelected
                  ? _chipSelectedTextColor
                  : _chipUnselectedTextColor,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: _chipUnselectedBackgroundColor,
            selectedColor: _chipSelectedColor,
            side: const BorderSide(color: Color(0xFF0F5FC9)),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
          );
        }).toList(growable: false),
      ),
    );
  }
}
