import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/breeding_record.dart';
import '../data/rabbit.dart';
import '../services/notification_service.dart';
import '../widgets/rabbit_widgets.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  List<Rabbit> _rabbits = [];
  List<BreedingRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final database = AppDatabase.instance;
    final rabbits = (await database.rabbits()).map(Rabbit.fromMap).toList();
    final records = (await database.breedingRecords())
        .map(BreedingRecord.fromMap)
        .toList();
    if (!mounted) return;
    setState(() {
      _rabbits = rabbits;
      _records = records;
      _loading = false;
    });
  }

  Future<void> _addRecord() async {
    final does = _rabbits.where((rabbit) => rabbit.gender == 'Female').toList();
    final bucks = _rabbits.where((rabbit) => rabbit.gender == 'Male').toList();
    if (does.isEmpty || bucks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one female and one male rabbit first.'),
        ),
      );
      return;
    }
    final result = await showDialog<_BreedingInput>(
      context: context,
      builder: (context) => _BreedingDialog(does: does, bucks: bucks),
    );
    if (result == null) return;
    final recordId = await AppDatabase.instance.saveBreedingRecord({
      'doe_id': result.doeId,
      'buck_id': result.buckId,
      'mating_date': result.matingDate.toIso8601String(),
      'status': 'Pending',
      'notes': result.notes,
    });
    var remindersScheduled = false;
    try {
      final doe = does.firstWhere((rabbit) => rabbit.id == result.doeId);
      remindersScheduled = await NotificationService.instance
          .scheduleKindlingReminders(
            breedingRecordId: recordId,
            doeName: doe.name,
            kindlingWindowStart: result.matingDate.add(
              const Duration(days: BreedingRecord.gestationWindowStartDays),
            ),
            typicalKindlingDate: result.matingDate.add(
              const Duration(days: BreedingRecord.typicalGestationDays),
            ),
          );
    } catch (_) {
      remindersScheduled = false;
    }
    await _load();
    widget.onChanged();
    if (mounted && !remindersScheduled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mating saved. Enable notifications in your phone settings to receive kindling reminders.',
          ),
        ),
      );
    }
  }

  Future<void> _recordKindling(BreedingRecord record) async {
    final count = await showDialog<int>(
      context: context,
      builder: (context) => const _KitCountDialog(),
    );
    if (count == null) return;
    await AppDatabase.instance.saveBreedingRecord({
      'doe_id': record.doeId,
      'buck_id': record.buckId,
      'mating_date': record.matingDate.toIso8601String(),
      'kindled_at': DateTime.now().toIso8601String(),
      'kit_count': count,
      'status': 'Kindled',
      'notes': record.notes,
    }, id: record.id);
    try {
      await NotificationService.instance.cancelKindlingReminders(record.id);
    } catch (_) {}
    await _load();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rabbitById = {for (final rabbit in _rabbits) rabbit.id: rabbit};
    return Scaffold(
      appBar: AppBar(title: const Text('Breeding')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.add),
        label: const Text('Record mating'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  _GuidanceBanner(),
                  const SizedBox(height: 18),
                  Text(
                    'Breeding records',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No breeding records yet. Add a mating date to estimate the kindling window.',
                      ),
                    )
                  else
                    for (final record in _records)
                      _BreedingRecordTile(
                        record: record,
                        doe: rabbitById[record.doeId],
                        buck: rabbitById[record.buckId],
                        onKindled: () => _recordKindling(record),
                      ),
                ],
              ),
            ),
    );
  }
}

class _BreedingInput {
  const _BreedingInput({
    required this.doeId,
    required this.buckId,
    required this.matingDate,
    this.notes,
  });

  final int doeId;
  final int buckId;
  final DateTime matingDate;
  final String? notes;
}

class _BreedingDialog extends StatefulWidget {
  const _BreedingDialog({required this.does, required this.bucks});

  final List<Rabbit> does;
  final List<Rabbit> bucks;

  @override
  State<_BreedingDialog> createState() => _BreedingDialogState();
}

class _BreedingDialogState extends State<_BreedingDialog> {
  int? _doeId;
  int? _buckId;
  DateTime _matingDate = DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _matingDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _matingDate = selected);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record mating'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Doe'),
            items: [
              for (final rabbit in widget.does)
                DropdownMenuItem(
                  value: rabbit.id,
                  child: Text('${rabbit.name} · ${rabbit.rabbitId}'),
                ),
            ],
            onChanged: (value) => setState(() => _doeId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Buck'),
            items: [
              for (final rabbit in widget.bucks)
                DropdownMenuItem(
                  value: rabbit.id,
                  child: Text('${rabbit.name} · ${rabbit.rabbitId}'),
                ),
            ],
            onChanged: (value) => setState(() => _buckId = value),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Mating date'),
            subtitle: Text(DateFormat.yMMMd().format(_matingDate)),
            onTap: _chooseDate,
          ),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _doeId == null || _buckId == null
            ? null
            : () => Navigator.pop(
                context,
                _BreedingInput(
                  doeId: _doeId!,
                  buckId: _buckId!,
                  matingDate: _matingDate,
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                ),
              ),
        child: const Text('Save'),
      ),
    ],
  );
}

class _KitCountDialog extends StatefulWidget {
  const _KitCountDialog();

  @override
  State<_KitCountDialog> createState() => _KitCountDialogState();
}

class _KitCountDialogState extends State<_KitCountDialog> {
  final _count = TextEditingController();

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record kindling'),
    content: TextField(
      controller: _count,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Number of kits'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(_count.text.trim());
          if (value != null && value >= 0) Navigator.pop(context, value);
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _BreedingRecordTile extends StatelessWidget {
  const _BreedingRecordTile({
    required this.record,
    required this.doe,
    required this.buck,
    required this.onKindled,
  });

  final BreedingRecord record;
  final Rabbit? doe;
  final Rabbit? buck;
  final VoidCallback onKindled;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final completed = record.status == 'Kindled';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${doe?.name ?? 'Unknown doe'} × ${buck?.name ?? 'Unknown buck'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(status: completed ? 'Kindled' : 'Breeding'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Mated ${dateFormat.format(record.matingDate)}'),
            if (completed) ...[
              Text(
                'Kindled ${dateFormat.format(record.kindledAt!)} · ${record.kitCount ?? 0} kits',
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Estimated kindling: ${dateFormat.format(record.estimatedKindlingStart)} – ${dateFormat.format(record.estimatedKindlingEnd)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Typical date: ${dateFormat.format(record.estimatedKindlingDate)}. Estimates vary; check the doe daily as the window approaches.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onKindled,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Record kindling'),
                ),
              ),
            ],
            if (record.notes?.isNotEmpty == true) Text(record.notes!),
          ],
        ),
      ),
    );
  }
}

class _GuidanceBanner extends StatelessWidget {
  const _GuidanceBanner();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preparing for kindling',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Many does kindle around 31 days after mating; a 28–33 day estimate is only a guide. Nest-building or fur-pulling may happen near kindling, but signs vary. Keep a clean nest box available and contact a rabbit-savvy vet if she seems unwell or labor is prolonged.',
          ),
        ],
      ),
    ),
  );
}
