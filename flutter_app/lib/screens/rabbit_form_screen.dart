import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_database.dart';
import '../data/photo_storage.dart';
import '../data/rabbit.dart';
import '../widgets/rabbit_widgets.dart';

class RabbitFormScreen extends StatefulWidget {
  const RabbitFormScreen({super.key, this.rabbit});

  final Rabbit? rabbit;

  @override
  State<RabbitFormScreen> createState() => _RabbitFormScreenState();
}

class _RabbitFormScreenState extends State<RabbitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _rabbitId = TextEditingController();
  final _breed = TextEditingController();
  final _color = TextEditingController();
  final _earTag = TextEditingController();
  final _weight = TextEditingController();
  final _location = TextEditingController();
  final _source = TextEditingController();
  final _notes = TextEditingController();
  String _gender = 'Unknown';
  String _status = 'Active';
  String _unit = 'kg';
  int? _fatherId;
  int? _motherId;
  DateTime? _dob;
  DateTime? _acquisitionDate;
  bool _estimatedDob = false;
  XFile? _photo;
  String? _existingPhoto;
  List<Map<String, Object?>> _males = [];
  List<Map<String, Object?>> _females = [];
  bool _saving = false;

  bool get _editing => widget.rabbit != null;

  @override
  void initState() {
    super.initState();
    final rabbit = widget.rabbit;
    if (rabbit != null) {
      _name.text = rabbit.name;
      _rabbitId.text = rabbit.rabbitId;
      _gender = rabbit.gender;
      _breed.text = rabbit.breed ?? '';
      _color.text = rabbit.color ?? '';
      _earTag.text = rabbit.earTag ?? '';
      _weight.text = rabbit.weight?.toString() ?? '';
      _unit = rabbit.weightUnit;
      _status = rabbit.status;
      _fatherId = rabbit.fatherId;
      _motherId = rabbit.motherId;
      _dob = rabbit.dateOfBirth ?? rabbit.estimatedBirthDate;
      _estimatedDob = rabbit.isEstimatedDob;
      _acquisitionDate = rabbit.acquisitionDate;
      _location.text = rabbit.location ?? '';
      _source.text = rabbit.source ?? '';
      _notes.text = rabbit.notes ?? '';
      _existingPhoto = rabbit.mainPhotoPath;
    }
    _loadParents();
  }

  Future<void> _loadParents() async {
    final males = await AppDatabase.instance.parents(
      exceptId: widget.rabbit?.id,
      gender: 'Male',
    );
    final females = await AppDatabase.instance.parents(
      exceptId: widget.rabbit?.id,
      gender: 'Female',
    );
    if (mounted) {
      setState(() {
        _males = males;
        _females = females;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _rabbitId,
      _breed,
      _color,
      _earTag,
      _weight,
      _location,
      _source,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseDate({required bool acquisition}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: acquisition
          ? _acquisitionDate ?? now
          : _dob ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (selected == null) return;
    setState(() {
      if (acquisition) {
        _acquisitionDate = selected;
      } else {
        _dob = selected;
      }
    });
  }

  Future<void> _choosePhoto() async {
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
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (image != null) {
      setState(() => _photo = image);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final weight = double.tryParse(_weight.text.trim());
      final values = <String, Object?>{
        'rabbit_id': _rabbitId.text.trim(),
        'name': _name.text.trim(),
        'gender': _gender,
        'breed': _nullable(_breed.text),
        'color': _nullable(_color.text),
        'date_of_birth': _dob != null && !_estimatedDob
            ? _dob!.toIso8601String()
            : null,
        'estimated_birth_date': _dob != null && _estimatedDob
            ? _dob!.toIso8601String()
            : null,
        'is_estimated_dob': _estimatedDob ? 1 : 0,
        'weight': weight,
        'weight_unit': _unit,
        'ear_tag': _nullable(_earTag.text),
        'status': _status,
        'father_id': _fatherId,
        'mother_id': _motherId,
        'acquisition_date': _acquisitionDate?.toIso8601String(),
        'source': _nullable(_source.text),
        'location': _nullable(_location.text),
        'notes': _nullable(_notes.text),
      };
      final id = await AppDatabase.instance.saveRabbit(
        values,
        id: widget.rabbit?.id,
      );
      if (_photo != null) {
        final path = await PhotoStorage.store(_photo!, id);
        await AppDatabase.instance.addPhoto(id, path, makeMain: true);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final message = error.toString().contains('UNIQUE')
            ? 'That Rabbit ID is already in use.'
            : 'Could not save rabbit: $error';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullable(String text) => text.trim().isEmpty ? null : text.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit rabbit' : 'New rabbit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _section('Basic information'),
            _field(
              _name,
              'Rabbit name *',
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            _field(
              _rabbitId,
              'Rabbit ID *',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a unique ID'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const ['Unknown', 'Female', 'Male']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: rabbitStatuses
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_breed, 'Breed')),
                const SizedBox(width: 10),
                Expanded(child: _field(_color, 'Color')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_earTag, 'Ear tag')),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    _weight,
                    'Weight',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        value != null &&
                            value.trim().isNotEmpty &&
                            (double.tryParse(value) == null ||
                                double.parse(value) <= 0)
                        ? 'Enter a valid weight'
                        : null,
                  ),
                ),
              ],
            ),
            if (_weight.text.isNotEmpty || true) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('kg')),
                    ButtonSegment(value: 'g', label: Text('g')),
                    ButtonSegment(value: 'lb', label: Text('lb')),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (value) =>
                      setState(() => _unit = value.first),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Estimated date of birth'),
              value: _estimatedDob,
              onChanged: (value) => setState(() => _estimatedDob = value),
            ),
            _dateTile(
              _estimatedDob ? 'Estimated DOB' : 'Date of birth',
              _dob,
              () => _chooseDate(acquisition: false),
              clear: () => setState(() => _dob = null),
            ),
            const SizedBox(height: 24),
            _section('Family'),
            DropdownButtonFormField<int?>(
              value: _fatherId,
              decoration: const InputDecoration(labelText: 'Father'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Unknown / not selected'),
                ),
                ..._males.map(
                  (row) => DropdownMenuItem<int?>(
                    value: row['id'] as int,
                    child: Text('${row['name']} · ${row['rabbit_id']}'),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _fatherId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _motherId,
              decoration: const InputDecoration(labelText: 'Mother'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Unknown / not selected'),
                ),
                ..._females.map(
                  (row) => DropdownMenuItem<int?>(
                    value: row['id'] as int,
                    child: Text('${row['name']} · ${row['rabbit_id']}'),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _motherId = value),
            ),
            const SizedBox(height: 24),
            _section('Management'),
            _field(_location, 'Cage / location'),
            const SizedBox(height: 12),
            _field(_source, 'Source'),
            const SizedBox(height: 8),
            _dateTile(
              'Acquisition date',
              _acquisitionDate,
              () => _chooseDate(acquisition: true),
              clear: () => setState(() => _acquisitionDate = null),
            ),
            const SizedBox(height: 24),
            _section('Notes'),
            _field(_notes, 'Notes', maxLines: 4),
            const SizedBox(height: 24),
            _section('Profile photo'),
            Row(
              children: [
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_photo!.path),
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  RabbitAvatar(path: _existingPhoto, size: 82, iconSize: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _choosePhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _photo == null ? 'Add or take photo' : 'Change photo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_editing ? 'Save changes' : 'Save Rabbit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SectionHeading(title),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: maxLines > 1,
    ),
  );

  Widget _dateTile(
    String title,
    DateTime? date,
    VoidCallback onTap, {
    required VoidCallback clear,
  }) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(title),
      subtitle: Text(date == null ? 'Not set' : dateLabel(date)),
      trailing: date == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              onPressed: clear,
              tooltip: 'Clear date',
              icon: const Icon(Icons.close),
            ),
    ),
  );
}
