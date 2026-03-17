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
            'คลังท่าบริหาร',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
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
                          fontWeight: FontWeight.w700,
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
                                      program.painLevel.label,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    'ทุก ${program.reminderIntervalMinutes} นาที',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(program.subtitle),
                              const SizedBox(height: 12),
                              ...program.exercises.map((exercise) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• '),
                                      Expanded(
                                        child: Text(
                                          '${exercise.name} (${exercise.durationSeconds} วินาที)'
                                          '${exercise.requiresStanding ? ' ลุกขึ้นทำ' : ''}',
                                        ),
                                      ),
                                    ],
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'MVP นี้ยังไม่เปิดหมวด ข้อมือ และ ตา เพราะข้อมูลท่าบริหารในเอกสารต้นทางยังไม่ครบพอสำหรับ recommendation ที่เชื่อถือได้',
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
