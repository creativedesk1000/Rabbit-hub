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
    await _saveRecord(result);
  }

  Future<void> _editRecord(BreedingRecord record) async {
    final does = _rabbits.where((rabbit) => rabbit.gender == 'Female').toList();
    final bucks = _rabbits.where((rabbit) => rabbit.gender == 'Male').toList();
    final result = await showDialog<_BreedingInput>(
      context: context,
      builder: (context) =>
          _BreedingDialog(does: does, bucks: bucks, initialRecord: record),
    );
    if (result == null) return;
    await _saveRecord(result, record: record);
  }

  Future<void> _recordBirth(BreedingRecord record) async {
    final does = _rabbits.where((rabbit) => rabbit.gender == 'Female').toList();
    final bucks = _rabbits.where((rabbit) => rabbit.gender == 'Male').toList();
    final result = await showDialog<_BreedingInput>(
      context: context,
      builder: (context) => _BreedingDialog(
        does: does,
        bucks: bucks,
        initialRecord: record,
        recordBirthImmediately: true,
      ),
    );
    if (result == null) return;
    await _saveRecord(result, record: record);
  }

  Future<void> _saveRecord(
    _BreedingInput input, {
    BreedingRecord? record,
  }) async {
    final recordId = await AppDatabase.instance.saveBreedingRecord({
      'doe_id': input.doeId,
      'buck_id': input.buckId,
      'mating_date': input.matingDate.toIso8601String(),
      'kindled_at': input.kindledAt?.toIso8601String(),
      'kit_count': input.kitCount,
      'status': input.kindledAt == null ? 'Pending' : 'Kindled',
      'notes': input.notes,
    }, id: record?.id);

    var remindersScheduled = true;
    try {
      await NotificationService.instance.cancelKindlingReminders(recordId);
      if (input.kindledAt == null) {
        final doe = _rabbits.firstWhere((rabbit) => rabbit.id == input.doeId);
        remindersScheduled = await NotificationService.instance
            .scheduleKindlingReminders(
              breedingRecordId: recordId,
              doeName: doe.name,
              kindlingWindowStart: input.matingDate.add(
                const Duration(days: BreedingRecord.gestationWindowStartDays),
              ),
              typicalKindlingDate: input.matingDate.add(
                const Duration(days: BreedingRecord.typicalGestationDays),
              ),
            );
      }
    } catch (_) {
      remindersScheduled = false;
    }
    await _load();
    widget.onChanged();
    if (mounted && !remindersScheduled && input.kindledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Record saved. Enable notifications in your phone settings to receive kindling reminders.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteRecord(BreedingRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete breeding record?'),
        content: const Text(
          'This removes the mating and any birth details recorded with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteBreedingRecord(record.id);
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
                        onEdit: () => _editRecord(record),
                        onDelete: () => _deleteRecord(record),
                        onRecordBirth: () => _recordBirth(record),
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
    this.kindledAt,
    this.kitCount,
    this.notes,
  });

  final int doeId;
  final int buckId;
  final DateTime matingDate;
  final DateTime? kindledAt;
  final int? kitCount;
  final String? notes;
}

class _BreedingDialog extends StatefulWidget {
  const _BreedingDialog({
    required this.does,
    required this.bucks,
    this.initialRecord,
    this.recordBirthImmediately = false,
  });

  final List<Rabbit> does;
  final List<Rabbit> bucks;
  final BreedingRecord? initialRecord;
  final bool recordBirthImmediately;

  @override
  State<_BreedingDialog> createState() => _BreedingDialogState();
}

class _BreedingDialogState extends State<_BreedingDialog> {
  int? _doeId;
  int? _buckId;
  DateTime _matingDate = DateTime.now();
  DateTime? _kindledAt;
  bool _birthRecorded = false;
  final _notes = TextEditingController();
  final _kitCount = TextEditingController();

  bool get _validBirthDetails {
    if (!_birthRecorded) return true;
    final count = int.tryParse(_kitCount.text.trim());
    final birthDate = _kindledAt;
    if (birthDate == null) return false;
    return _kindledAt != null &&
        !DateTime(birthDate.year, birthDate.month, birthDate.day).isBefore(
          DateTime(_matingDate.year, _matingDate.month, _matingDate.day),
        ) &&
        count != null &&
        count >= 0;
  }

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    if (record != null) {
      _doeId = record.doeId;
      _buckId = record.buckId;
      _matingDate = record.matingDate;
      _kindledAt =
          record.kindledAt ??
          (widget.recordBirthImmediately ? DateTime.now() : null);
      _birthRecorded =
          record.status == 'Kindled' || widget.recordBirthImmediately;
      _kitCount.text = record.kitCount?.toString() ?? '';
      _notes.text = record.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _kitCount.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _matingDate.isAfter(DateTime.now())
          ? DateTime.now()
          : _matingDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _matingDate = selected);
  }

  Future<void> _chooseKindledDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _kindledAt == null || _kindledAt!.isAfter(today)
          ? today
          : _kindledAt!,
      firstDate: DateTime(1990),
      lastDate: today,
    );
    if (selected != null) setState(() => _kindledAt = selected);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initialRecord == null ? 'Record mating' : 'Edit record'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: widget.does.any((rabbit) => rabbit.id == _doeId)
                ? _doeId
                : null,
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
            value: widget.bucks.any((rabbit) => rabbit.id == _buckId)
                ? _buckId
                : null,
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Birth recorded'),
            subtitle: const Text(
              'Add the actual birth date and number of kits',
            ),
            value: _birthRecorded,
            onChanged: (value) => setState(() {
              _birthRecorded = value;
              _kindledAt ??= DateTime.now();
            }),
          ),
          if (_birthRecorded) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Actual birth date'),
              subtitle: Text(
                _kindledAt == null
                    ? 'Choose the date'
                    : DateFormat.yMMMd().format(_kindledAt!),
              ),
              onTap: _chooseKindledDate,
            ),
            TextField(
              controller: _kitCount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of babies',
                helperText: 'Enter 0 if the litter did not survive.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (!_validBirthDetails)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Enter a valid kit count and a birth date on or after the mating date.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
          const SizedBox(height: 8),
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
        onPressed: _doeId == null || _buckId == null || !_validBirthDetails
            ? null
            : () => Navigator.pop(
                context,
                _BreedingInput(
                  doeId: _doeId!,
                  buckId: _buckId!,
                  matingDate: _matingDate,
                  kindledAt: _birthRecorded ? _kindledAt : null,
                  kitCount: _birthRecorded
                      ? int.parse(_kitCount.text.trim())
                      : null,
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                ),
              ),
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
    required this.onEdit,
    required this.onDelete,
    required this.onRecordBirth,
  });

  final BreedingRecord record;
  final Rabbit? doe;
  final Rabbit? buck;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRecordBirth;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final completed = record.status == 'Kindled';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                PopupMenuButton<String>(
                  tooltip: 'Breeding record actions',
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit record')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete record'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Mated ${dateFormat.format(record.matingDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (completed) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.child_friendly_outlined,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Born ${dateFormat.format(record.kindledAt ?? record.matingDate)} · ${record.kitCount ?? 0} babies',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
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
            ],
            if (record.notes?.isNotEmpty == true) Text(record.notes!),
            if (!completed)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRecordBirth,
                  icon: const Icon(Icons.child_friendly_outlined),
                  label: const Text('Record birth'),
                ),
              ),
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
