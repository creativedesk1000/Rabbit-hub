import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/app_database.dart';
import 'package:flutter_app/data/breeding_record.dart';
import 'package:flutter_app/data/rabbit.dart';

void main() {
  setUp(() async {
    await AppDatabase.instance.useDatabaseForTesting(
      await AppDatabase.createInMemoryForTesting(),
    );
  });

  test('unknown date of birth is handled without forcing an exact date', () {
    final rabbit = Rabbit(
      id: 1,
      rabbitId: 'RH-001',
      name: 'Bella',
      gender: 'Female',
      status: 'Active',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    expect(rabbit.ageLabel, 'Age unknown');
    expect(rabbit.dateOfBirthLabel, 'Not recorded');
  });

  test('estimated birth date is clearly marked as approximate', () {
    final rabbit = Rabbit(
      id: 2,
      rabbitId: 'RH-002',
      name: 'Clover',
      gender: 'Female',
      status: 'Growing',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      estimatedBirthDate: DateTime.now(),
      isEstimatedDob: true,
    );

    expect(rabbit.ageLabel, startsWith('Approx.'));
    expect(rabbit.dateOfBirthLabel, startsWith('Estimated:'));
  });

  test('breeding record estimates a 28 to 33 day kindling window', () {
    final breeding = BreedingRecord(
      id: 1,
      doeId: 2,
      buckId: 3,
      matingDate: DateTime(2026, 10, 1),
      status: 'Pending',
    );

    expect(breeding.estimatedKindlingStart, DateTime(2026, 10, 29));
    expect(breeding.estimatedKindlingDate, DateTime(2026, 11, 1));
    expect(breeding.estimatedKindlingEnd, DateTime(2026, 11, 3));
  });

  test(
    'rabbit, photo, weight and history records use separate local tables',
    () async {
      final database = await AppDatabase.instance.database;
      final now = DateTime.now();
      final rabbitId = await AppDatabase.instance.saveRabbit({
        'rabbit_id': 'RH-001',
        'name': 'Bella',
        'gender': 'Female',
        'status': 'Active',
        'weight': 2.4,
        'weight_unit': 'kg',
      });

      await AppDatabase.instance.addPhoto(rabbitId, r'C:\photos\bella.jpg');
      await AppDatabase.instance.addWeight(
        rabbitId,
        2.5,
        'kg',
        now.add(const Duration(minutes: 1)),
        'Weekly check',
      );

      final rabbit = Rabbit.fromMap(
        (await AppDatabase.instance.rabbit(rabbitId))!,
      );
      final photos = await AppDatabase.instance.photos(rabbitId);
      final weights = await AppDatabase.instance.weights(rabbitId);
      final history = await AppDatabase.instance.history(rabbitId);

      expect(rabbit.name, 'Bella');
      expect(rabbit.mainPhotoPath, r'C:\photos\bella.jpg');
      expect(photos, hasLength(1));
      expect(photos.single['is_main'], 1);
      expect(weights, hasLength(2));
      expect(weights.first['notes'], 'Weekly check');
      expect(
        history.map((event) => event['event_type']),
        containsAll(['rabbit_created', 'photo_added', 'weight_updated']),
      );
      expect(await database.query('app_settings'), isEmpty);
    },
  );

  test('rabbit IDs are unique and self-parenting is rejected', () async {
    final firstId = await AppDatabase.instance.saveRabbit({
      'rabbit_id': 'RH-001',
      'name': 'Bella',
      'gender': 'Female',
      'status': 'Active',
    });

    await expectLater(
      AppDatabase.instance.saveRabbit({
        'rabbit_id': 'rh-001',
        'name': 'Duplicate',
        'gender': 'Unknown',
        'status': 'Active',
      }),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      AppDatabase.instance.saveRabbit({
        'rabbit_id': 'RH-002',
        'name': 'Loop',
        'gender': 'Male',
        'status': 'Active',
        'father_id': firstId,
      }, id: firstId),
      throwsA(isA<Exception>()),
    );
  });

  test('breeding and kindling records update doe status and history', () async {
    final doeId = await AppDatabase.instance.saveRabbit({
      'rabbit_id': 'DOE-001',
      'name': 'Clover',
      'gender': 'Female',
      'status': 'Active',
    });
    final buckId = await AppDatabase.instance.saveRabbit({
      'rabbit_id': 'BUCK-001',
      'name': 'Basil',
      'gender': 'Male',
      'status': 'Active',
    });
    final matingDate = DateTime(2026, 10, 1);

    final recordId = await AppDatabase.instance.saveBreedingRecord({
      'doe_id': doeId,
      'buck_id': buckId,
      'mating_date': matingDate.toIso8601String(),
      'status': 'Pending',
    });
    expect((await AppDatabase.instance.rabbit(doeId))!['status'], 'Pregnant');

    await AppDatabase.instance.saveBreedingRecord({
      'doe_id': doeId,
      'buck_id': buckId,
      'mating_date': matingDate.toIso8601String(),
      'kindled_at': DateTime(2026, 11, 1).toIso8601String(),
      'kit_count': 5,
      'status': 'Kindled',
    }, id: recordId);

    expect((await AppDatabase.instance.rabbit(doeId))!['status'], 'Nursing');
    expect(
      (await AppDatabase.instance.breedingRecords()).single['kit_count'],
      5,
    );
    expect(
      (await AppDatabase.instance.history(
        doeId,
      )).map((event) => event['event_type']),
      containsAll(['breeding_recorded', 'kindling_recorded']),
    );
  });

  test(
    'breeding and birth details can be rewritten and the record deleted',
    () async {
      final originalDoeId = await AppDatabase.instance.saveRabbit({
        'rabbit_id': 'DOE-001',
        'name': 'Clover',
        'gender': 'Female',
        'status': 'Active',
      });
      final correctedDoeId = await AppDatabase.instance.saveRabbit({
        'rabbit_id': 'DOE-002',
        'name': 'Hazel',
        'gender': 'Female',
        'status': 'Active',
      });
      final buckId = await AppDatabase.instance.saveRabbit({
        'rabbit_id': 'BUCK-001',
        'name': 'Basil',
        'gender': 'Male',
        'status': 'Active',
      });
      final recordId = await AppDatabase.instance.saveBreedingRecord({
        'doe_id': originalDoeId,
        'buck_id': buckId,
        'mating_date': DateTime(2026, 10, 1).toIso8601String(),
        'status': 'Pending',
      });

      await AppDatabase.instance.saveBreedingRecord({
        'doe_id': correctedDoeId,
        'buck_id': buckId,
        'mating_date': DateTime(2026, 10, 2).toIso8601String(),
        'kindled_at': DateTime(2026, 11, 4).toIso8601String(),
        'kit_count': 6,
        'status': 'Kindled',
        'notes': 'Corrected birth details',
      }, id: recordId);

      var record = BreedingRecord.fromMap(
        (await AppDatabase.instance.breedingRecords()).single,
      );
      expect(record.doeId, correctedDoeId);
      expect(record.matingDate, DateTime(2026, 10, 2));
      expect(record.kindledAt, DateTime(2026, 11, 4));
      expect(record.kitCount, 6);
      expect(record.notes, 'Corrected birth details');
      expect(
        (await AppDatabase.instance.rabbit(originalDoeId))!['status'],
        'Active',
      );
      expect(
        (await AppDatabase.instance.rabbit(correctedDoeId))!['status'],
        'Nursing',
      );

      await AppDatabase.instance.saveBreedingRecord({
        'doe_id': correctedDoeId,
        'buck_id': buckId,
        'mating_date': DateTime(2026, 10, 2).toIso8601String(),
        'kindled_at': DateTime(2026, 11, 5).toIso8601String(),
        'kit_count': 5,
        'status': 'Kindled',
        'notes': 'Final corrected details',
      }, id: recordId);
      record = BreedingRecord.fromMap(
        (await AppDatabase.instance.breedingRecords()).single,
      );
      expect(record.kindledAt, DateTime(2026, 11, 5));
      expect(record.kitCount, 5);

      await AppDatabase.instance.saveBreedingRecord({
        'doe_id': correctedDoeId,
        'buck_id': buckId,
        'mating_date': DateTime(2026, 10, 2).toIso8601String(),
        'kindled_at': null,
        'kit_count': null,
        'status': 'Pending',
        'notes': 'Birth details removed',
      }, id: recordId);
      record = BreedingRecord.fromMap(
        (await AppDatabase.instance.breedingRecords()).single,
      );
      expect(record.status, 'Pending');
      expect(record.kindledAt, isNull);
      expect(record.kitCount, isNull);
      expect(
        (await AppDatabase.instance.rabbit(correctedDoeId))!['status'],
        'Pregnant',
      );

      await AppDatabase.instance.deleteBreedingRecord(recordId);

      expect(await AppDatabase.instance.breedingRecords(), isEmpty);
      expect(
        (await AppDatabase.instance.rabbit(correctedDoeId))!['status'],
        'Active',
      );
      expect(
        (await AppDatabase.instance.history(
          correctedDoeId,
        )).map((event) => event['event_type']),
        contains('breeding_record_deleted'),
      );
    },
  );
}
