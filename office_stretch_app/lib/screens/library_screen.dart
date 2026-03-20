import 'package:flutter/material.dart';

import '../app/app_keys.dart';
import '../app/app_state.dart';
import '../models/app_models.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({
    super.key,
    required this.appState,
    required this.onStartProgram,
  });

  final AppState appState;
  final ValueChanged<ExerciseProgram> onStartProgram;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        key: AppKeys.libraryScreen,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'คลังโปรแกรมยืดเส้น',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ดูโปรแกรมตามจุดปวดและระดับอาการ แล้วเริ่มรอบได้จากหน้านี้โดยตรง',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          ...PainArea.values.map((area) {
            final programs = appState.programsByArea[area] ?? const [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(area.description),
                      const SizedBox(height: 16),
                      ...programs.map((program) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      program.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    'ทุก ${program.reminderIntervalMinutes} นาที',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(program.subtitle),
                              const SizedBox(height: 12),
                              ...program.exercises.map((exercise) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    key: AppKeys.libraryExercisePreview(
                                      exercise.id,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: Colors.white.withValues(
                                        alpha: 0.76,
                                      ),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _ExercisePreviewThumb(
                                          exercise: exercise,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.name,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                exercise.description,
                                                style: theme
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(height: 1.3),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _LibraryMetaChip(
                                                    icon: Icons.timer_outlined,
                                                    label:
                                                        '${exercise.durationSeconds} วินาที',
                                                  ),
                                                  _LibraryMetaChip(
                                                    icon:
                                                        exercise.requiresStanding
                                                        ? Icons
                                                              .stairs_outlined
                                                        : Icons
                                                              .event_seat_outlined,
                                                    label:
                                                        exercise.requiresStanding
                                                        ? 'แนะนำให้ยืนทำ'
                                                        : 'ทำขณะนั่งได้',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  key: AppKeys.libraryStartProgram(program.id),
                                  onPressed: () => onStartProgram(program),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('เริ่มโปรแกรมนี้'),
                                ),
                              ),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'อยู่ในแผนถัดไป',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'เวอร์ชันนี้ยังไม่เปิดหมวดข้อมือและตา เพราะข้อมูลท่าบริหารต้นทางยังไม่ครบพอสำหรับ recommendation ที่น่าเชื่อถือ',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewThumb extends StatelessWidget {
  const _ExercisePreviewThumb({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 78,
      width: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FCFF), Color(0xFFF0FFE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: exercise.imageAssetPath == null
          ? Icon(
              Icons.self_improvement_outlined,
              color: theme.colorScheme.primary,
            )
          : Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                exercise.imageAssetPath!,
                fit: BoxFit.contain,
                semanticLabel: exercise.name,
              ),
            ),
    );
  }
}

class _LibraryMetaChip extends StatelessWidget {
  const _LibraryMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
