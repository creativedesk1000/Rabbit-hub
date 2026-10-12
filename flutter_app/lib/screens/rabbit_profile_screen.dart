import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/photo_storage.dart';
import '../data/rabbit.dart';
import '../widgets/rabbit_widgets.dart';
import 'rabbit_form_screen.dart';

class RabbitProfileScreen extends StatefulWidget {
  const RabbitProfileScreen({super.key, required this.rabbitId});

  final int rabbitId;

  @override
  State<RabbitProfileScreen> createState() => _RabbitProfileScreenState();
}

class _RabbitProfileScreenState extends State<RabbitProfileScreen> {
  Rabbit? _rabbit;
  List<Map<String, Object?>> _photos = [];
  List<Map<String, Object?>> _history = [];
  List<Map<String, Object?>> _weights = [];
  Map<int, String> _familyNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final database = AppDatabase.instance;
    final row = await database.rabbit(widget.rabbitId);
    if (row == null) return;
    final rabbit = Rabbit.fromMap(row);
    final photos = await database.photos(rabbit.id);
    final history = await database.history(rabbit.id);
    final weights = await database.weights(rabbit.id);
    final allRabbits = await database.rabbits();
    final names = {
      for (final item in allRabbits) item['id'] as int: item['name'] as String,
    };
    if (!mounted) return;
    setState(() {
      _rabbit = rabbit;
      _photos = photos;
      _history = history;
      _weights = weights;
      _familyNames = names;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final rabbit = _rabbit;
    if (rabbit == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RabbitFormScreen(rabbit: rabbit)),
    );
    if (saved == true) _load();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );
    final rabbit = _rabbit;
    if (photo == null || rabbit == null) return;
    final path = await PhotoStorage.store(photo, rabbit.id);
    await AppDatabase.instance.addPhoto(rabbit.id, path);
    await _load();
  }

  Future<void> _setMainPhoto(Map<String, Object?> photo) async {
    final rabbit = _rabbit;
    if (rabbit == null || photo['is_main'] == 1) return;
    await AppDatabase.instance.setMainPhoto(photo['id'] as int, rabbit.id);
    await _load();
  }

  Future<void> _addWeight() async {
    final rabbit = _rabbit;
    if (rabbit == null) return;
    final valueController = TextEditingController();
    final noteController = TextEditingController();
    String unit = rabbit.weightUnit;
    final result = await showDialog<(double, String, String?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record weight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'e.g. 2.4',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: const ['kg', 'g', 'lb']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => unit = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(valueController.text.trim());
                if (value == null || value <= 0) return;
                Navigator.pop(context, (
                  value,
                  unit,
                  noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                ));
              },
              child: const Text('Save weight'),
            ),
          ],
        ),
      ),
    );
    valueController.dispose();
    noteController.dispose();
    if (result == null) return;
    await AppDatabase.instance.addWeight(
      rabbit.id,
      result.$1,
      result.$2,
      DateTime.now(),
      result.$3,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final rabbit = _rabbit;
    if (rabbit == null) {
      return const Scaffold(
        body: Center(child: Text('Rabbit profile not found.')),
      );
    }
    final currentWeight = _weights.isEmpty ? null : _weights.first;
    final previousWeight = _weights.length < 2 ? null : _weights[1];
    final weightChange = currentWeight == null || previousWeight == null
        ? null
        : (currentWeight['weight'] as num).toDouble() -
              (previousWeight['weight'] as num).toDouble();
    final father = rabbit.fatherId == null
        ? null
        : _familyNames[rabbit.fatherId];
    final mother = rabbit.motherId == null
        ? null
        : _familyNames[rabbit.motherId];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabbit profile'),
        actions: [
          IconButton(
            onPressed: _edit,
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
          children: [
            _ProfileHeader(rabbit: rabbit, onEdit: _edit),
            const SizedBox(height: 18),
            _ProfileSection(
              title: 'Basic information',
              trailing: IconButton(
                onPressed: _edit,
                tooltip: 'Edit basic information',
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              child: Column(
                children: [
                  _info('Date of birth', rabbit.dateOfBirthLabel),
                  _info('Age', rabbit.ageLabel),
                  _info(
                    'Weight',
                    rabbit.weight == null
                        ? 'Not recorded'
                        : '${rabbit.weight} ${rabbit.weightUnit}',
                  ),
                  _info('Color', _value(rabbit.color)),
                  _info('Ear tag', _value(rabbit.earTag)),
                  _info('Cage / location', _value(rabbit.location), last: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              title: 'Family',
              child: Column(
                children: [
                  _info('Mother', mother ?? 'Not recorded'),
                  _info('Father', father ?? 'Not recorded', last: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              title: 'Weight',
              trailing: IconButton(
                onPressed: _addWeight,
                tooltip: 'Record weight',
                icon: const Icon(Icons.add),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rabbit.weight == null)
                    const Text('No weight recorded yet.')
                  else
                    Text(
                      'Current: ${rabbit.weight} ${rabbit.weightUnit}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (previousWeight != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Previous: ${previousWeight['weight']} ${previousWeight['unit']}',
                    ),
                    Text(
                      'Change: ${weightChange! >= 0 ? '+' : ''}${weightChange.toStringAsFixed(2)} ${currentWeight!['unit']}',
                    ),
                  ],
                  if (_weights.isNotEmpty) ...[
                    const Divider(height: 22),
                    for (final item in _weights.take(5))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.monitor_weight_outlined),
                        title: Text('${item['weight']} ${item['unit']}'),
                        subtitle: Text(
                          DateFormat.yMMMd().format(
                                DateTime.parse(item['recorded_at'] as String),
                              ) +
                              ((item['notes'] as String?)?.isNotEmpty == true
                                  ? ' · ${item['notes']}'
                                  : ''),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              title: 'Notes',
              child: Text(
                rabbit.notes?.isNotEmpty == true
                    ? rabbit.notes!
                    : 'No notes added.',
              ),
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              title: 'Photos',
              trailing: IconButton(
                onPressed: _addPhoto,
                tooltip: 'Add photo',
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
              child: _photos.isEmpty
                  ? const Text(
                      'No photos yet. Add a profile photo or a photo to the history.',
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final photo in _photos)
                          _PhotoTile(
                            photo: photo,
                            onTap: () => _setMainPhoto(photo),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              title: 'History',
              child: _history.isEmpty
                  ? const Text('Profile events will appear here.')
                  : Column(
                      children: [
                        for (final item in _history) _HistoryItem(item: item),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _value(String? value) =>
      value?.trim().isNotEmpty == true ? value! : 'Not recorded';

  Widget _info(String label, String value, {bool last = false}) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.rabbit, required this.onEdit});

  final Rabbit rabbit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final file = rabbit.mainPhotoPath == null
        ? null
        : File(rabbit.mainPhotoPath!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: file != null && file.existsSync()
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ProfilePhotoPlaceholder(),
                  )
                : const _ProfilePhotoPlaceholder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rabbit.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${rabbit.rabbitId}  ·  ${rabbit.gender}${rabbit.breed?.isNotEmpty == true ? '  ·  ${rabbit.breed}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(status: rabbit.status),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onEdit,
              tooltip: 'Edit rabbit',
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfilePhotoPlaceholder extends StatelessWidget {
  const _ProfilePhotoPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Center(
      child: Icon(
        Icons.cruelty_free_rounded,
        size: 76,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onTap});

  final Map<String, Object?> photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final path = photo['path'] as String;
    final main = photo['is_main'] == 1;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(path),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 96,
                height: 96,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (main)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFC97755),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item});

  final Map<String, Object?> item;

  @override
  Widget build(BuildContext context) {
    final type = item['event_type'] as String;
    final icon = switch (type) {
      'rabbit_created' => Icons.cruelty_free_rounded,
      'weight_updated' => Icons.monitor_weight_outlined,
      'photo_added' => Icons.photo_camera_back_outlined,
      'status_changed' => Icons.swap_horiz_rounded,
      _ => Icons.edit_note_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((item['details'] as String?)?.isNotEmpty == true)
                  Text(item['details'] as String),
                const SizedBox(height: 3),
                Text(
                  DateFormat.yMMMd().add_jm().format(
                    DateTime.parse(item['occurred_at'] as String),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
