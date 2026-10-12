import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../widgets/rabbit_widgets.dart';

const healthStatuses = [
  'Healthy',
  'Monitoring',
  'Sick',
  'Under Treatment',
  'Recovering',
  'Recovered',
  'Critical',
  'Unknown',
];

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, this.onOpenRabbit});

  final ValueChanged<int>? onOpenRabbit;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  List<Map<String, Object?>> _checks = [];
  List<Map<String, Object?>> _problems = [];
  List<Map<String, Object?>> _medicines = [];
  Map<int, String> _rabbitNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final checks = await db.healthChecks();
    final problems = await db.healthProblems(activeOnly: true);
    final medicines = await db.medicines();
    final rabbits = await db.rabbits();
    if (!mounted) return;
    setState(() {
      _checks = checks.take(12).toList();
      _problems = problems;
      _medicines = medicines;
      _rabbitNames = {
        for (final row in rabbits) row['id'] as int: row['name'] as String,
      };
      _loading = false;
    });
  }

  Future<List<Map<String, Object?>>> _chooseRabbitRows() =>
      AppDatabase.instance.rabbits();

  Future<void> _newHealthCheck() async {
    final rabbits = await _chooseRabbitRows();
    if (!mounted) return;
    if (rabbits.isEmpty) {
      _notice('Add a rabbit before recording a health check.');
      return;
    }
    int? rabbitId = rabbits.first['id'] as int;
    String status = 'Healthy';
    final notes = TextEditingController();
    final fields = <String, String>{};
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Health check'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: rabbitId,
                      decoration: const InputDecoration(labelText: 'Rabbit'),
                      items: rabbits
                          .map(
                            (row) => DropdownMenuItem(
                              value: row['id'] as int,
                              child: Text(
                                '${row['name']} · ${row['rabbit_id']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => refresh(() => rabbitId = value),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in const [
                      (
                        'Appetite',
                        ['Normal', 'Reduced', 'Not eating', 'Unknown'],
                      ),
                      (
                        'Water intake',
                        ['Normal', 'Reduced', 'Increased', 'Unknown'],
                      ),
                      (
                        'Activity',
                        ['Normal', 'Reduced', 'Lethargic', 'Unknown'],
                      ),
                      (
                        'Body condition',
                        ['Good', 'Thin', 'Overweight', 'Unknown'],
                      ),
                      (
                        'Eyes',
                        ['Normal', 'Discharge', 'Redness', 'Swelling', 'Other'],
                      ),
                      ('Nose', ['Normal', 'Discharge', 'Sneezing', 'Other']),
                      (
                        'Ears',
                        [
                          'Normal',
                          'Wax',
                          'Possible mites',
                          'Wound',
                          'Swelling',
                          'Other',
                        ],
                      ),
                      (
                        'Teeth',
                        [
                          'Normal',
                          'Overgrown',
                          'Drooling',
                          'Difficulty eating',
                          'Other',
                        ],
                      ),
                      (
                        'Skin / fur',
                        [
                          'Normal',
                          'Hair loss',
                          'Parasites',
                          'Wound',
                          'Itching',
                          'Swelling',
                          'Other',
                        ],
                      ),
                      (
                        'Feet',
                        [
                          'Normal',
                          'Sore hocks',
                          'Swelling',
                          'Injury',
                          'Wound',
                          'Other',
                        ],
                      ),
                      (
                        'Digestion',
                        [
                          'Normal droppings',
                          'Reduced droppings',
                          'Soft stool',
                          'Diarrhea',
                          'Other',
                        ],
                      ),
                    ]) ...[
                      DropdownButtonFormField<String>(
                        value: fields[entry.$1] ?? entry.$2.first,
                        decoration: InputDecoration(labelText: entry.$1),
                        items: entry.$2
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            refresh(() => fields[entry.$1] = value!),
                      ),
                      const SizedBox(height: 9),
                    ],
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Overall status',
                      ),
                      items: healthStatuses
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => refresh(() => status = value!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save check'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || rabbitId == null) {
      notes.dispose();
      return;
    }
    final values = <String, Object?>{
      'rabbit_id': rabbitId,
      'checked_at': DateTime.now().toIso8601String(),
      'overall_status': status,
      'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
      for (final item in fields.entries) _columnName(item.key): item.value,
    };
    notes.dispose();
    try {
      await AppDatabase.instance.saveHealthCheck(values);
      await _load();
      _notice('Health check saved.');
    } catch (_) {
      _notice('Could not save record. Please try again.');
    }
  }

  String _columnName(String label) => switch (label) {
    'Water intake' => 'water_intake',
    'Body condition' => 'body_condition',
    'Skin / fur' => 'skin_fur',
    _ => label.toLowerCase(),
  };

  Future<void> _newProblem() async {
    final rabbits = await _chooseRabbitRows();
    if (!mounted) return;
    if (rabbits.isEmpty) {
      _notice('Add a rabbit before recording a health problem.');
      return;
    }
    int? rabbitId = rabbits.first['id'] as int;
    String severity = 'Mild';
    String status = 'Active';
    final problem = TextEditingController();
    final symptoms = TextEditingController();
    final notes = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Record health problem'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: rabbitId,
                    decoration: const InputDecoration(labelText: 'Rabbit'),
                    items: rabbits
                        .map(
                          (row) => DropdownMenuItem(
                            value: row['id'] as int,
                            child: Text(row['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refresh(() => rabbitId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: problem,
                    decoration: const InputDecoration(labelText: 'Problem *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: symptoms,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Symptoms'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: severity,
                    decoration: const InputDecoration(labelText: 'Severity'),
                    items: const ['Mild', 'Moderate', 'Severe', 'Critical']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refresh(() => severity = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items:
                        const [
                              'Active',
                              'Monitoring',
                              'Under Treatment',
                              'Resolved',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => refresh(() => status = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, problem.text.trim().isNotEmpty),
              child: const Text('Save problem'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && rabbitId != null) {
      try {
        await AppDatabase.instance.saveHealthProblem({
          'rabbit_id': rabbitId,
          'problem': problem.text.trim(),
          'discovered_at': DateTime.now().toIso8601String(),
          'symptoms': symptoms.text.trim(),
          'severity': severity,
          'status': status,
          'notes': notes.text.trim(),
        });
        await _load();
      } catch (_) {
        _notice('Could not save record. Please try again.');
      }
    }
    problem.dispose();
    symptoms.dispose();
    notes.dispose();
  }

  Future<void> _newMedicine() async {
    final rabbits = await _chooseRabbitRows();
    if (!mounted) return;
    if (rabbits.isEmpty) {
      _notice('Add a rabbit before recording a medicine.');
      return;
    }
    int? rabbitId = rabbits.first['id'] as int;
    final controllers = {
      for (final key in [
        'Medicine name',
        'Reason',
        'Dose',
        'Dose unit',
        'Route',
        'Duration',
        'Frequency',
        'Number of doses',
        'Next dose (minutes from now)',
        'Vet / clinic',
        'Prescription notes',
        'Additional notes',
      ])
        key: TextEditingController(),
    };
    final startedAt = DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('New treatment'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: rabbitId,
                    decoration: const InputDecoration(labelText: 'Rabbit'),
                    items: rabbits
                        .map(
                          (row) => DropdownMenuItem(
                            value: row['id'] as int,
                            child: Text(row['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refresh(() => rabbitId = value),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in controllers.entries) ...[
                    TextField(
                      controller: entry.value,
                      keyboardType:
                          entry.key == 'Number of doses' ||
                              entry.key.startsWith('Next dose')
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: entry.key),
                    ),
                    const SizedBox(height: 9),
                  ],
                  Text(
                    'Started ${DateFormat.yMMMd().add_jm().format(startedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Enter medicine and dosage information as directed by your veterinarian.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                controllers['Medicine name']!.text.trim().isNotEmpty,
              ),
              child: const Text('Save treatment'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && rabbitId != null) {
      final values = <String, Object?>{
        'rabbit_id': rabbitId,
        'medicine_name': controllers['Medicine name']!.text.trim(),
        'reason': _text(controllers, 'Reason'),
        'dose': _text(controllers, 'Dose'),
        'dose_unit': _text(controllers, 'Dose unit'),
        'route': _text(controllers, 'Route'),
        'started_at': startedAt.toIso8601String(),
        'time_of_day': DateFormat.Hm().format(startedAt),
        'duration': _text(controllers, 'Duration'),
        'frequency': _text(controllers, 'Frequency'),
        'number_of_doses': int.tryParse(controllers['Number of doses']!.text),
        'vet_clinic': _text(controllers, 'Vet / clinic'),
        'prescription_notes': _text(controllers, 'Prescription notes'),
        'notes': _text(controllers, 'Additional notes'),
        'status': 'Active',
      };
      final nextMinutes = int.tryParse(
        controllers['Next dose (minutes from now)']!.text,
      );
      if (nextMinutes != null && nextMinutes > 0) {
        values['next_dose_at'] = startedAt
            .add(Duration(minutes: nextMinutes))
            .toIso8601String();
      }
      try {
        await AppDatabase.instance.saveMedicine(values);
        await _load();
      } catch (_) {
        _notice('Could not save record. Please try again.');
      }
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  String? _text(Map<String, TextEditingController> controllers, String key) {
    final value = controllers[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final active = _medicines
        .where((row) => row['status'] == 'Active')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & medicine'),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _newHealthCheck,
                          icon: const Icon(Icons.health_and_safety_outlined),
                          label: const Text('Health check'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _newProblem,
                          icon: const Icon(Icons.add_alert_outlined),
                          label: const Text('Health problem'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: _newMedicine,
                    icon: const Icon(Icons.medication_outlined),
                    label: const Text('New treatment'),
                  ),
                  const SizedBox(height: 22),
                  SectionHeading('Current problems'),
                  if (_problems.isEmpty)
                    const Text('No current health problems recorded.'),
                  for (final row in _problems)
                    _ProblemTile(
                      row: row,
                      rabbitName: _rabbitNames[row['rabbit_id']],
                      onResolve: () async {
                        await AppDatabase.instance.updateHealthProblemStatus(
                          row['id'] as int,
                          'Resolved',
                        );
                        await _load();
                      },
                    ),
                  const SizedBox(height: 20),
                  SectionHeading('Active treatments'),
                  if (active.isEmpty) const Text('No active treatments.'),
                  for (final row in active)
                    _MedicineTile(
                      row: row,
                      rabbitName: _rabbitNames[row['rabbit_id']],
                    ),
                  const SizedBox(height: 20),
                  SectionHeading('Recent checks'),
                  if (_checks.isEmpty)
                    const Text('Health checks will appear here.'),
                  for (final row in _checks.take(8))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(
                        '${_rabbitNames[row['rabbit_id']] ?? 'Rabbit'} · ${row['overall_status']}',
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().format(
                              DateTime.parse(row['checked_at'] as String),
                            ) +
                            ((row['notes'] as String?)?.isNotEmpty == true
                                ? ' · ${row['notes']}'
                                : ''),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SectionHeading('Treatment history'),
                  for (final row
                      in _medicines
                          .where((row) => row['status'] != 'Active')
                          .take(8))
                    _MedicineTile(
                      row: row,
                      rabbitName: _rabbitNames[row['rabbit_id']],
                    ),
                ],
              ),
            ),
    );
  }
}

class _ProblemTile extends StatelessWidget {
  const _ProblemTile({
    required this.row,
    required this.rabbitName,
    required this.onResolve,
  });
  final Map<String, Object?> row;
  final String? rabbitName;
  final VoidCallback onResolve;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.healing_outlined, color: Color(0xFFB45B45)),
      title: Text('${row['problem']} · ${row['severity']}'),
      subtitle: Text('${rabbitName ?? 'Rabbit'} · ${row['status']}'),
      trailing: IconButton(
        onPressed: onResolve,
        tooltip: 'Mark resolved',
        icon: const Icon(Icons.check_circle_outline),
      ),
    ),
  );
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile({required this.row, required this.rabbitName});
  final Map<String, Object?> row;
  final String? rabbitName;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.medication_outlined),
      title: Text(row['medicine_name'] as String),
      subtitle: Text(
        '${rabbitName ?? 'Rabbit'} · ${row['status']}${row['dose'] == null ? '' : ' · ${row['dose']} ${row['dose_unit'] ?? ''}'}',
      ),
      trailing: row['status'] == 'Active'
          ? PopupMenuButton<String>(
              tooltip: 'Treatment actions',
              onSelected: (value) async {
                await AppDatabase.instance.updateMedicineStatus(
                  row['id'] as int,
                  value,
                );
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'Completed',
                  child: Text('Mark completed'),
                ),
                PopupMenuItem(value: 'Paused', child: Text('Pause treatment')),
              ],
            )
          : null,
    ),
  );
}
