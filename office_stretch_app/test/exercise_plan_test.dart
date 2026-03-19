import 'package:flutter_test/flutter_test.dart';
import 'package:office_stretch_app/data/exercise_catalog.dart';
import 'package:office_stretch_app/models/app_models.dart';

void main() {
  test('normalizes a single selected group to at most two exercises', () {
    final plan = ExerciseCatalog.buildPlan(
      const UserProfile(
        painSelections: [
          PainSelection(
            area: PainArea.neckShoulders,
            level: PainLevel.high,
            selectedExerciseIds: <String>[],
          ),
        ],
        workHours: WorkHours.fourToSix,
        stretchHabit: StretchHabit.sometimes,
      ),
    );

    expect(plan.groups, hasLength(1));
    expect(plan.groups.first.selectedExerciseIds, hasLength(2));
    expect(plan.exerciseCount, 2);
    expect(plan.reminderIntervalMinutes, 30);
  });

  test('builds a combined plan across multiple pain groups', () {
    final plan = ExerciseCatalog.buildPlan(
      const UserProfile(
        painSelections: [
          PainSelection(
            area: PainArea.neckShoulders,
            level: PainLevel.medium,
            selectedExerciseIds: <String>[],
          ),
          PainSelection(
            area: PainArea.upperBack,
            level: PainLevel.low,
            selectedExerciseIds: <String>[],
          ),
          PainSelection(
            area: PainArea.lowerBack,
            level: PainLevel.medium,
            selectedExerciseIds: <String>[],
          ),
        ],
        workHours: WorkHours.sevenToNine,
        stretchHabit: StretchHabit.never,
      ),
    );

    expect(plan.groups, hasLength(3));
    expect(plan.exerciseCount, 5);
    expect(plan.groups[0].selectedExerciseIds, hasLength(2));
    expect(plan.groups[1].selectedExerciseIds, hasLength(1));
    expect(plan.groups[2].selectedExerciseIds, hasLength(2));
    expect(plan.reminderIntervalMinutes, 45);
  });

  test('keeps only the user-selected exercises for collections larger than two', () {
    final available = ExerciseCatalog.programFor(
      PainArea.lowerBack,
      PainLevel.medium,
    ).exercises;

    final chosenIds = <String>[
      available[1].id,
      available[2].id,
    ];

    final plan = ExerciseCatalog.buildPlan(
      UserProfile(
        painSelections: [
          PainSelection(
            area: PainArea.lowerBack,
            level: PainLevel.medium,
            selectedExerciseIds: chosenIds,
          ),
        ],
        workHours: WorkHours.oneToThree,
        stretchHabit: StretchHabit.often,
      ),
    );

    expect(plan.groups.first.selectedExerciseIds, chosenIds);
    expect(
      plan.exercises.map((entry) => entry.exercise.id).toList(growable: false),
      chosenIds,
    );
  });
}
