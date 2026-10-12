import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb && Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final directory = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      '${directory.path}/rabbit_hub.db',
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createPart3Schema(db);
        if (oldVersion < 3) await _createBreedingSchema(db);
      },
    );
    return _database!;
  }

  Future<void> useDatabaseForTesting(Database database) async {
    await _database?.close();
    _database = database;
  }

  static Future<Database> createInMemoryForTesting() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createPart3Schema(db);
          if (oldVersion < 3) await _createBreedingSchema(db);
        },
      ),
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
          CREATE TABLE rabbits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rabbit_id TEXT NOT NULL COLLATE NOCASE UNIQUE,
            name TEXT NOT NULL,
            gender TEXT NOT NULL,
            breed TEXT,
            color TEXT,
            date_of_birth TEXT,
            estimated_birth_date TEXT,
            is_estimated_dob INTEGER NOT NULL DEFAULT 0,
            weight REAL,
            weight_unit TEXT NOT NULL DEFAULT 'kg',
            ear_tag TEXT,
            status TEXT NOT NULL DEFAULT 'Active',
            father_id INTEGER REFERENCES rabbits(id) ON DELETE SET NULL,
            mother_id INTEGER REFERENCES rabbits(id) ON DELETE SET NULL,
            acquisition_date TEXT,
            source TEXT,
            location TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            CHECK (father_id IS NULL OR father_id != id),
            CHECK (mother_id IS NULL OR mother_id != id)
          )
        ''');
    await db.execute('''
          CREATE TABLE rabbit_photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
            path TEXT NOT NULL,
            caption TEXT,
            is_main INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE weight_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
            weight REAL NOT NULL,
            unit TEXT NOT NULL,
            recorded_at TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE rabbit_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
            event_type TEXT NOT NULL,
            title TEXT NOT NULL,
            details TEXT,
            occurred_at TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE app_settings (
            setting_key TEXT PRIMARY KEY,
            setting_value TEXT NOT NULL
          )
        ''');
    await db.execute('CREATE INDEX idx_rabbits_status ON rabbits(status)');
    await db.execute(
      'CREATE INDEX idx_history_rabbit_date ON rabbit_history(rabbit_id, occurred_at)',
    );
    await db.execute(
      'CREATE INDEX idx_weight_rabbit_date ON weight_records(rabbit_id, recorded_at)',
    );
    await _createPart3Schema(db);
    await _createBreedingSchema(db);
  }

  static Future<void> _createBreedingSchema(Database db) async {
    await db.execute('''
      CREATE TABLE breeding_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doe_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
        buck_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
        mating_date TEXT NOT NULL,
        kindled_at TEXT,
        kit_count INTEGER,
        status TEXT NOT NULL DEFAULT 'Pending',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        CHECK (doe_id != buck_id),
        CHECK (kit_count IS NULL OR kit_count >= 0)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_breeding_doe_status_date ON breeding_records(doe_id, status, mating_date)',
    );
  }

  static Future<void> _createPart3Schema(Database db) async {
    await db.execute('''
      CREATE TABLE health_checks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
        checked_at TEXT NOT NULL,
        appetite TEXT,
        water_intake TEXT,
        activity TEXT,
        body_condition TEXT,
        weight REAL,
        weight_unit TEXT,
        eyes TEXT,
        nose TEXT,
        ears TEXT,
        teeth TEXT,
        skin_fur TEXT,
        feet TEXT,
        digestion TEXT,
        overall_status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE health_problems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
        problem TEXT NOT NULL,
        discovered_at TEXT NOT NULL,
        symptoms TEXT,
        severity TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Active',
        notes TEXT,
        resolved_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE health_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        health_check_id INTEGER REFERENCES health_checks(id) ON DELETE CASCADE,
        problem_id INTEGER REFERENCES health_problems(id) ON DELETE CASCADE,
        path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        CHECK (health_check_id IS NOT NULL OR problem_id IS NOT NULL)
      )
    ''');
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
        medicine_name TEXT NOT NULL,
        reason TEXT,
        dose TEXT,
        dose_unit TEXT,
        route TEXT,
        started_at TEXT NOT NULL,
        time_of_day TEXT,
        duration TEXT,
        frequency TEXT,
        number_of_doses INTEGER,
        next_dose_at TEXT,
        end_date TEXT,
        vet_clinic TEXT,
        prescription_notes TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'Active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medicine_administrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
        rabbit_id INTEGER NOT NULL REFERENCES rabbits(id) ON DELETE CASCADE,
        due_at TEXT,
        administered_at TEXT,
        outcome TEXT NOT NULL,
        dose TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rabbit_id INTEGER REFERENCES rabbits(id) ON DELETE SET NULL,
        medicine_id INTEGER REFERENCES medicines(id) ON DELETE SET NULL,
        parent_reminder_id INTEGER REFERENCES reminders(id) ON DELETE SET NULL,
        title TEXT NOT NULL,
        reminder_type TEXT NOT NULL,
        due_at TEXT NOT NULL,
        repeat_rule TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'Pending',
        completed_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE reminder_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reminder_id INTEGER NOT NULL REFERENCES reminders(id) ON DELETE CASCADE,
        action TEXT NOT NULL,
        action_at TEXT NOT NULL,
        notes TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_health_checks_rabbit_date ON health_checks(rabbit_id, checked_at)',
    );
    await db.execute(
      'CREATE INDEX idx_health_problems_rabbit_status ON health_problems(rabbit_id, status)',
    );
    await db.execute(
      'CREATE INDEX idx_medicines_rabbit_status ON medicines(rabbit_id, status)',
    );
    await db.execute(
      'CREATE INDEX idx_medicine_admin_due ON medicine_administrations(rabbit_id, due_at)',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_due_status ON reminders(status, due_at)',
    );
    await db.execute(
      'CREATE INDEX idx_reminders_rabbit ON reminders(rabbit_id, due_at)',
    );
  }

  Future<List<Map<String, Object?>>> rabbits() async {
    final db = await database;
    return db.rawQuery('''
      SELECT r.*, p.path AS main_photo_path
      FROM rabbits r
      LEFT JOIN rabbit_photos p ON p.rabbit_id = r.id AND p.is_main = 1
      ORDER BY r.name COLLATE NOCASE
    ''');
  }

  Future<Map<String, Object?>?> rabbit(int id) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT r.*, p.path AS main_photo_path
      FROM rabbits r
      LEFT JOIN rabbit_photos p ON p.rabbit_id = r.id AND p.is_main = 1
      WHERE r.id = ?
    ''',
      [id],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> photos(int rabbitId) async {
    final db = await database;
    return db.query(
      'rabbit_photos',
      where: 'rabbit_id = ?',
      whereArgs: [rabbitId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> history(int rabbitId) async {
    final db = await database;
    return db.query(
      'rabbit_history',
      where: 'rabbit_id = ?',
      whereArgs: [rabbitId],
      orderBy: 'occurred_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> weights(int rabbitId) async {
    final db = await database;
    return db.query(
      'weight_records',
      where: 'rabbit_id = ?',
      whereArgs: [rabbitId],
      orderBy: 'recorded_at DESC, id DESC',
    );
  }

  Future<List<Map<String, Object?>>> parents({
    int? exceptId,
    String? gender,
  }) async {
    final db = await database;
    final clauses = <String>[];
    final args = <Object?>[];
    if (exceptId != null) {
      clauses.add('id != ?');
      args.add(exceptId);
    }
    if (gender != null) {
      clauses.add('gender = ?');
      args.add(gender);
    }
    return db.query(
      'rabbits',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE',
    );
  }

  Future<int> saveRabbit(Map<String, Object?> values, {int? id}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final oldRows = id == null
          ? <Map<String, Object?>>[]
          : await txn.query('rabbits', where: 'id = ?', whereArgs: [id]);
      final old = oldRows.isEmpty ? null : oldRows.first;
      final savedValues = {...values, 'updated_at': now};
      int rabbitKey;
      if (old == null) {
        rabbitKey = await txn.insert('rabbits', {
          ...savedValues,
          'created_at': now,
        });
        await _addHistory(
          txn,
          rabbitKey,
          'rabbit_created',
          'Rabbit created',
          null,
          now,
        );
      } else {
        await txn.update(
          'rabbits',
          savedValues,
          where: 'id = ?',
          whereArgs: [id],
        );
        rabbitKey = id!;
        await _addHistory(
          txn,
          rabbitKey,
          'profile_updated',
          'Profile updated',
          null,
          now,
        );
        if (old['status'] != values['status']) {
          await _addHistory(
            txn,
            rabbitKey,
            'status_changed',
            'Status changed',
            '${old['status']} → ${values['status']}',
            now,
          );
        }
      }
      final newWeight = values['weight'] as double?;
      final oldWeight = (old?['weight'] as num?)?.toDouble();
      if (newWeight != null && newWeight != oldWeight) {
        await txn.insert('weight_records', {
          'rabbit_id': rabbitKey,
          'weight': newWeight,
          'unit': values['weight_unit'] ?? 'kg',
          'recorded_at': now,
          'created_at': now,
        });
        if (old != null) {
          await _addHistory(
            txn,
            rabbitKey,
            'weight_updated',
            'Weight updated',
            '$oldWeight → $newWeight ${values['weight_unit'] ?? 'kg'}',
            now,
          );
        }
      }
      return rabbitKey;
    });
  }

  Future<int> saveBreedingRecord(Map<String, Object?> values, {int? id}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final recordId =
          id ??
          await txn.insert('breeding_records', {
            ...values,
            'created_at': now,
            'updated_at': now,
          });
      if (id != null) {
        await txn.update(
          'breeding_records',
          {...values, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      final doeId = values['doe_id'] as int;
      final status = values['status'] as String;
      final rabbitStatus = status == 'Kindled' ? 'Nursing' : 'Pregnant';
      await txn.update(
        'rabbits',
        {'status': rabbitStatus, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [doeId],
      );
      await _addHistory(
        txn,
        doeId,
        status == 'Kindled' ? 'kindling_recorded' : 'breeding_recorded',
        status == 'Kindled' ? 'Kindling recorded' : 'Breeding recorded',
        status == 'Kindled'
            ? '${values['kit_count'] ?? 0} kits recorded'
            : 'Mating date: ${values['mating_date']}',
        status == 'Kindled' ? values['kindled_at'] as String? ?? now : now,
      );
      return recordId;
    });
  }

  Future<List<Map<String, Object?>>> breedingRecords({
    int? doeId,
    String? status,
  }) async {
    final db = await database;
    final filters = <String>[];
    final args = <Object?>[];
    if (doeId != null) {
      filters.add('doe_id = ?');
      args.add(doeId);
    }
    if (status != null) {
      filters.add('status = ?');
      args.add(status);
    }
    return db.query(
      'breeding_records',
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'mating_date DESC, id DESC',
    );
  }

  Future<void> addWeight(
    int rabbitId,
    double weight,
    String unit,
    DateTime date,
    String? notes,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final previous = await txn.query(
        'weight_records',
        where: 'rabbit_id = ?',
        whereArgs: [rabbitId],
        orderBy: 'recorded_at DESC, id DESC',
        limit: 1,
      );
      await txn.insert('weight_records', {
        'rabbit_id': rabbitId,
        'weight': weight,
        'unit': unit,
        'recorded_at': date.toIso8601String(),
        'notes': notes,
        'created_at': now,
      });
      await txn.update(
        'rabbits',
        {'weight': weight, 'weight_unit': unit, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [rabbitId],
      );
      final detail = previous.isEmpty
          ? '$weight $unit'
          : '${(previous.first['weight'] as num).toDouble()} → $weight $unit';
      await _addHistory(
        txn,
        rabbitId,
        'weight_updated',
        'Weight updated',
        detail,
        date.toIso8601String(),
      );
    });
  }

  Future<void> addPhoto(
    int rabbitId,
    String path, {
    bool makeMain = false,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'rabbit_photos',
        where: 'rabbit_id = ?',
        whereArgs: [rabbitId],
      );
      if (makeMain) {
        await txn.update(
          'rabbit_photos',
          {'is_main': 0},
          where: 'rabbit_id = ?',
          whereArgs: [rabbitId],
        );
      }
      await txn.insert('rabbit_photos', {
        'rabbit_id': rabbitId,
        'path': path,
        'is_main': makeMain || existing.isEmpty ? 1 : 0,
        'created_at': now,
      });
      await txn.update(
        'rabbits',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [rabbitId],
      );
      await _addHistory(txn, rabbitId, 'photo_added', 'Photo added', null, now);
    });
  }

  Future<void> setMainPhoto(int photoId, int rabbitId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'rabbit_photos',
        {'is_main': 0},
        where: 'rabbit_id = ?',
        whereArgs: [rabbitId],
      );
      await txn.update(
        'rabbit_photos',
        {'is_main': 1},
        where: 'id = ?',
        whereArgs: [photoId],
      );
      await txn.update(
        'rabbits',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [rabbitId],
      );
    });
  }

  Future<int> saveHealthCheck(Map<String, Object?> values) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('health_checks', {...values, 'created_at': now});
    final rabbitId = values['rabbit_id'] as int;
    await _addHistory(
      db,
      rabbitId,
      'health_check',
      'Health check',
      values['overall_status'] as String?,
      values['checked_at'] as String? ?? now,
    );
    return id;
  }

  Future<void> addHealthPhoto({
    int? healthCheckId,
    int? problemId,
    required String path,
  }) async {
    final db = await database;
    await db.insert('health_photos', {
      'health_check_id': healthCheckId,
      'problem_id': problemId,
      'path': path,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> healthChecks({int? rabbitId}) async {
    final db = await database;
    return db.query(
      'health_checks',
      where: rabbitId == null ? null : 'rabbit_id = ?',
      whereArgs: rabbitId == null ? null : [rabbitId],
      orderBy: 'checked_at DESC, id DESC',
    );
  }

  Future<List<Map<String, Object?>>> healthProblems({
    int? rabbitId,
    bool activeOnly = false,
  }) async {
    final db = await database;
    final filters = <String>[];
    final args = <Object?>[];
    if (rabbitId != null) {
      filters.add('rabbit_id = ?');
      args.add(rabbitId);
    }
    if (activeOnly) {
      filters.add("status != 'Resolved'");
    }
    return db.query(
      'health_problems',
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'discovered_at DESC, id DESC',
    );
  }

  Future<int> saveHealthProblem(Map<String, Object?> values, {int? id}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final problemId = await (id == null
        ? db.insert('health_problems', {
            ...values,
            'created_at': now,
            'updated_at': now,
          })
        : Future<int>.value(id));
    if (id != null) {
      await db.update(
        'health_problems',
        {...values, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await _addHistory(
      db,
      values['rabbit_id'] as int,
      'health_problem',
      id == null ? 'Health problem recorded' : 'Health problem updated',
      values['problem'] as String?,
      values['discovered_at'] as String? ?? now,
    );
    return problemId;
  }

  Future<void> updateHealthProblemStatus(int id, String status) async {
    final db = await database;
    final rows = await db.query(
      'health_problems',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'health_problems',
      {
        'status': status,
        'resolved_at': status == 'Resolved' ? now : null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _addHistory(
      db,
      rows.first['rabbit_id'] as int,
      status == 'Resolved' ? 'health_recovered' : 'health_problem',
      status == 'Resolved'
          ? 'Health problem resolved'
          : 'Health status updated',
      rows.first['problem'] as String?,
      now,
    );
  }

  Future<int> saveMedicine(Map<String, Object?> values) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('medicines', {
      ...values,
      'created_at': now,
      'updated_at': now,
    });
    final rabbitId = values['rabbit_id'] as int;
    await _addHistory(
      db,
      rabbitId,
      'medicine_started',
      'Treatment started',
      values['medicine_name'] as String?,
      values['started_at'] as String? ?? now,
    );
    final nextDose = values['next_dose_at'] as String?;
    if (nextDose != null && nextDose.isNotEmpty) {
      await db.insert('reminders', {
        'rabbit_id': rabbitId,
        'medicine_id': id,
        'title': 'Medicine due: ${values['medicine_name']}',
        'reminder_type': 'Medicine',
        'due_at': nextDose,
        'notes': values['dose'] == null
            ? null
            : 'Dose: ${values['dose']} ${values['dose_unit'] ?? ''}',
        'created_at': now,
      });
    }
    return id;
  }

  Future<List<Map<String, Object?>>> medicines({
    int? rabbitId,
    String? status,
  }) async {
    final db = await database;
    final filters = <String>[];
    final args = <Object?>[];
    if (rabbitId != null) {
      filters.add('rabbit_id = ?');
      args.add(rabbitId);
    }
    if (status != null) {
      filters.add('status = ?');
      args.add(status);
    }
    return db.query(
      'medicines',
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'started_at DESC, id DESC',
    );
  }

  Future<void> updateMedicineStatus(int id, String status) async {
    final db = await database;
    final rows = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'medicines',
      {'status': status, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _addHistory(
      db,
      rows.first['rabbit_id'] as int,
      status == 'Completed' ? 'medicine_completed' : 'medicine_updated',
      status == 'Completed' ? 'Treatment completed' : 'Treatment updated',
      rows.first['medicine_name'] as String?,
      now,
    );
  }

  Future<List<Map<String, Object?>>> medicineAdministrations(
    int medicineId,
  ) async {
    final db = await database;
    return db.query(
      'medicine_administrations',
      where: 'medicine_id = ?',
      whereArgs: [medicineId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> saveReminder(Map<String, Object?> values) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('reminders', {...values, 'created_at': now});
  }

  Future<List<Map<String, Object?>>> reminders({
    DateTime? from,
    DateTime? to,
    bool pendingOnly = false,
    int? rabbitId,
  }) async {
    final db = await database;
    final filters = <String>[];
    final args = <Object?>[];
    if (from != null) {
      filters.add('due_at >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      filters.add('due_at <= ?');
      args.add(to.toIso8601String());
    }
    if (pendingOnly) filters.add("status = 'Pending'");
    if (rabbitId != null) {
      filters.add('rabbit_id = ?');
      args.add(rabbitId);
    }
    return db.rawQuery('''
      SELECT reminders.*, rabbits.name AS rabbit_name, rabbits.rabbit_id AS rabbit_code
      FROM reminders LEFT JOIN rabbits ON rabbits.id = reminders.rabbit_id
      ${filters.isEmpty ? '' : 'WHERE ${filters.join(' AND ')}'}
      ORDER BY reminders.due_at
    ''', args);
  }

  Future<void> finishReminder(
    int reminderId,
    String outcome, {
    String? notes,
  }) async {
    final db = await database;
    final rows = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [reminderId],
    );
    if (rows.isEmpty) return;
    final reminder = rows.first;
    final now = DateTime.now();
    await db.transaction((txn) async {
      await txn.update(
        'reminders',
        {'status': outcome, 'completed_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [reminderId],
      );
      await txn.insert('reminder_history', {
        'reminder_id': reminderId,
        'action': outcome,
        'action_at': now.toIso8601String(),
        'notes': notes,
      });
      final medicineId = reminder['medicine_id'] as int?;
      final rabbitId = reminder['rabbit_id'] as int?;
      if (medicineId != null && rabbitId != null) {
        await txn.insert('medicine_administrations', {
          'medicine_id': medicineId,
          'rabbit_id': rabbitId,
          'due_at': reminder['due_at'],
          'administered_at': outcome == 'Given' ? now.toIso8601String() : null,
          'outcome': outcome,
          'notes': notes,
          'created_at': now.toIso8601String(),
        });
        await _addHistory(
          txn,
          rabbitId,
          'medicine_dose',
          outcome == 'Given'
              ? 'Medicine administered'
              : 'Medicine dose skipped',
          reminder['title'] as String?,
          now.toIso8601String(),
        );
      } else if (rabbitId != null) {
        await _addHistory(
          txn,
          rabbitId,
          'reminder',
          'Reminder $outcome',
          reminder['title'] as String?,
          now.toIso8601String(),
        );
      }
      final repeat = reminder['repeat_rule'] as String?;
      if (outcome == 'Completed' && repeat != null && repeat != 'None') {
        final due = DateTime.parse(reminder['due_at'] as String);
        final nextDue = switch (repeat) {
          'Daily' => due.add(const Duration(days: 1)),
          'Weekly' => due.add(const Duration(days: 7)),
          'Monthly' => DateTime(
            due.year,
            due.month + 1,
            due.day,
            due.hour,
            due.minute,
          ),
          _ => null,
        };
        if (nextDue != null) {
          await txn.insert('reminders', {
            'rabbit_id': rabbitId,
            'medicine_id': reminder['medicine_id'],
            'parent_reminder_id': reminderId,
            'title': reminder['title'],
            'reminder_type': reminder['reminder_type'],
            'due_at': nextDue.toIso8601String(),
            'repeat_rule': repeat,
            'notes': reminder['notes'],
            'created_at': now.toIso8601String(),
          });
        }
      }
    });
  }

  Future<void> rescheduleReminder(int reminderId, DateTime dueAt) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'reminders',
        {
          'due_at': dueAt.toIso8601String(),
          'status': 'Pending',
          'completed_at': null,
        },
        where: 'id = ?',
        whereArgs: [reminderId],
      );
      await txn.insert('reminder_history', {
        'reminder_id': reminderId,
        'action': 'Rescheduled',
        'action_at': now,
      });
    });
  }

  Future<List<Map<String, Object?>>> allRows(String table) async {
    const allowed = {
      'rabbits',
      'rabbit_photos',
      'weight_records',
      'rabbit_history',
      'app_settings',
      'health_checks',
      'health_problems',
      'health_photos',
      'medicines',
      'medicine_administrations',
      'reminders',
      'reminder_history',
    };
    if (!allowed.contains(table)) throw ArgumentError.value(table, 'table');
    final db = await database;
    return db.query(table);
  }

  Future<Map<String, int>> reportCounts() async {
    final db = await database;
    Future<int> count(String table, [String? where]) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM $table${where == null ? '' : ' WHERE $where'}',
      );
      return (rows.first['total'] as int?) ?? 0;
    }

    return {
      'rabbits': await count('rabbits'),
      'male': await count('rabbits', "gender = 'Male'"),
      'female': await count('rabbits', "gender = 'Female'"),
      'healthChecks': await count('health_checks'),
      'activeProblems': await count('health_problems', "status != 'Resolved'"),
      'sickRabbits': await count(
        'rabbits',
        "status IN ('Sick', 'Under Treatment')",
      ),
      'activeTreatments': await count('medicines', "status = 'Active'"),
      'completedTreatments': await count('medicines', "status = 'Completed'"),
      'pendingReminders': await count('reminders', "status = 'Pending'"),
      'completedReminders': await count('reminders', "status != 'Pending'"),
      'weights': await count('weight_records'),
    };
  }

  Future<Map<String, String>> settings() async {
    final db = await database;
    final rows = await db.query('app_settings');
    return {
      for (final row in rows)
        row['setting_key'] as String: row['setting_value'] as String,
    };
  }

  Future<void> setSettings(Map<String, String> values) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in values.entries) {
      batch.insert('app_settings', {
        'setting_key': entry.key,
        'setting_value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _addHistory(
    DatabaseExecutor db,
    int rabbitId,
    String type,
    String title,
    String? details,
    String when,
  ) async {
    await db.insert('rabbit_history', {
      'rabbit_id': rabbitId,
      'event_type': type,
      'title': title,
      'details': details,
      'occurred_at': when,
    });
  }
}
