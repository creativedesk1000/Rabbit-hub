import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';
import '../data/breeding_record.dart';
import '../data/rabbit.dart';
import '../main.dart';
import '../widgets/rabbit_widgets.dart';
import 'rabbit_form_screen.dart';
import 'rabbit_list_screen.dart';
import 'rabbit_profile_screen.dart';
import 'breeding_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _contentRevision = 0;
  String _farmName = 'Rabbit Hub';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppDatabase.instance.settings();
    if (!mounted) return;
    setState(
      () => _farmName = settings['farm_name']?.trim().isNotEmpty == true
          ? settings['farm_name']!
          : 'Rabbit Hub',
    );
    themeModeNotifier.value = switch (settings['theme'] ?? 'Light') {
      'Dark' => ThemeMode.dark,
      'System' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<void> _openForm({Rabbit? rabbit}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RabbitFormScreen(rabbit: rabbit)),
    );
    if (saved == true && mounted) {
      _loadSettings();
      setState(() => _contentRevision++);
    }
  }

  Future<void> _openRabbit(Rabbit rabbit) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RabbitProfileScreen(rabbitId: rabbit.id),
      ),
    );
    if (mounted) setState(() => _contentRevision++);
  }

  void _selectTab(int index) {
    if (index == 2) {
      _openForm();
      return;
    }
    setState(() => _index = index > 2 ? index - 1 : index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        key: ValueKey('dashboard-$_contentRevision'),
        farmName: _farmName,
        onAddRabbit: () => _openForm(),
        onViewRabbits: () => setState(() => _index = 1),
        onOpenRabbit: _openRabbit,
        onAddPhoto: _quickPhoto,
      ),
      RabbitListScreen(
        key: ValueKey('rabbits-$_contentRevision'),
        onOpenRabbit: _openRabbit,
        onAddRabbit: () => _openForm(),
      ),
      BreedingScreen(
        key: ValueKey('breeding-$_contentRevision'),
        onChanged: () {
          if (mounted) setState(() => _contentRevision++);
        },
      ),
      SettingsScreen(
        key: ValueKey('settings-$_contentRevision'),
        onSettingsChanged: _loadSettings,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index > 1 ? _index + 1 : _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.cruelty_free_outlined),
            selectedIcon: Icon(Icons.cruelty_free_rounded),
            label: 'Rabbits',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Future<void> _quickPhoto() async {
    final rabbits = (await AppDatabase.instance.rabbits())
        .map(Rabbit.fromMap)
        .toList();
    if (!mounted) return;
    if (rabbits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a rabbit before attaching photos.')),
      );
      return;
    }
    final rabbit = await showModalBottomSheet<Rabbit>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            Text(
              'Choose a rabbit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final item in rabbits)
              ListTile(
                leading: RabbitAvatar(path: item.mainPhotoPath, size: 44),
                title: Text(item.name),
                subtitle: Text(item.rabbitId),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (rabbit == null || !mounted) return;
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
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final folder = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/rabbit_hub_photos',
    );
    await folder.create(recursive: true);
    final saved = await File(picked.path).copy(
      '${folder.path}/${rabbit.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await AppDatabase.instance.addPhoto(rabbit.id, saved.path);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo added to ${rabbit.name}.')));
      setState(() {});
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.farmName,
    required this.onAddRabbit,
    required this.onViewRabbits,
    required this.onOpenRabbit,
    required this.onAddPhoto,
  });

  final String farmName;
  final VoidCallback onAddRabbit;
  final VoidCallback onViewRabbits;
  final ValueChanged<Rabbit> onOpenRabbit;
  final VoidCallback onAddPhoto;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Rabbit> _rabbits = [];
  List<BreedingRecord> _breedingRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final database = AppDatabase.instance;
    final rows = await database.rabbits();
    final breedingRows = await database.breedingRecords(status: 'Pending');
    if (!mounted) return;
    setState(() {
      _rabbits = rows.map(Rabbit.fromMap).toList();
      _breedingRecords = breedingRows.map(BreedingRecord.fromMap).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final males = _rabbits.where((rabbit) => rabbit.gender == 'Male').length;
    final females = _rabbits
        .where((rabbit) => rabbit.gender == 'Female')
        .length;
    final pregnant = _rabbits
        .where((rabbit) => rabbit.status == 'Pregnant')
        .length;
    final nursing = _rabbits
        .where((rabbit) => rabbit.status == 'Nursing')
        .length;
    final sick = _rabbits
        .where(
          (rabbit) =>
              rabbit.status == 'Sick' || rabbit.status == 'Under Treatment',
        )
        .length;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.farmName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Your herd, at a glance',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: widget.onAddPhoto,
                    tooltip: 'Add photo',
                    icon: const Icon(Icons.add_a_photo_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _HerdBanner(total: _rabbits.length, onTap: widget.onViewRabbits),
              if (_rabbits.isNotEmpty) ...[
                const SizedBox(height: 14),
                _RabbitFamilyCarousel(
                  rabbits: _rabbits,
                  onOpenRabbit: widget.onOpenRabbit,
                ),
              ],
              if (_breedingRecords.isNotEmpty) ...[
                const SizedBox(height: 22),
                SectionHeading('Kindling watch'),
                const SizedBox(height: 8),
                for (final record
                    in (_breedingRecords.toList()..sort(
                          (a, b) => a.estimatedKindlingDate.compareTo(
                            b.estimatedKindlingDate,
                          ),
                        ))
                        .take(2))
                  _KindlingAlert(
                    record: record,
                    doe: _rabbitById(record.doeId),
                  ),
              ],
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _MetricCard(
                    label: 'Male rabbits',
                    count: males,
                    icon: Icons.male_rounded,
                    tint: const Color(0xFF6283A1),
                  ),
                  _MetricCard(
                    label: 'Female rabbits',
                    count: females,
                    icon: Icons.female_rounded,
                    tint: const Color(0xFFB97079),
                  ),
                  _MetricCard(
                    label: 'Pregnant',
                    count: pregnant,
                    icon: Icons.favorite_border_rounded,
                    tint: const Color(0xFF9B5E6F),
                  ),
                  _MetricCard(
                    label: 'Nursing',
                    count: nursing,
                    icon: Icons.cruelty_free_rounded,
                    tint: const Color(0xFF7C8050),
                  ),
                  _MetricCard(
                    label: 'Needs attention',
                    count: sick,
                    icon: Icons.health_and_safety_outlined,
                    tint: const Color(0xFFB45B45),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeading('Quick actions'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onAddRabbit,
                      icon: const Icon(Icons.add),
                      label: const Text('Add rabbit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onViewRabbits,
                      icon: const Icon(Icons.cruelty_free_rounded),
                      label: const Text('View rabbits'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeading(
                'Recently added',
                action: 'All rabbits',
                onAction: widget.onViewRabbits,
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_rabbits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Your rabbit records will appear here.'),
                )
              else
                for (final rabbit
                    in (_rabbits.toList()
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                        .take(3))
                  RabbitSummaryLine(
                    rabbit: rabbit,
                    onTap: () => widget.onOpenRabbit(rabbit),
                  ),
              if (_rabbits.isNotEmpty) ...[
                const SizedBox(height: 14),
                SectionHeading('Recently updated'),
                for (final rabbit
                    in (_rabbits.toList()
                          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
                        .take(2))
                  RabbitSummaryLine(
                    rabbit: rabbit,
                    onTap: () => widget.onOpenRabbit(rabbit),
                  ),
              ],
              if (_rabbits.isEmpty) ...[
                const SizedBox(height: 18),
                Center(
                  child: TextButton.icon(
                    onPressed: widget.onAddRabbit,
                    icon: const Icon(Icons.add),
                    label: const Text('Create the first rabbit profile'),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Rabbit? _rabbitById(int id) {
    for (final rabbit in _rabbits) {
      if (rabbit.id == id) return rabbit;
    }
    return null;
  }
}

class _RabbitFamilyCarousel extends StatefulWidget {
  const _RabbitFamilyCarousel({
    required this.rabbits,
    required this.onOpenRabbit,
  });

  final List<Rabbit> rabbits;
  final ValueChanged<Rabbit> onOpenRabbit;

  @override
  State<_RabbitFamilyCarousel> createState() => _RabbitFamilyCarouselState();
}

class _RabbitFamilyCarouselState extends State<_RabbitFamilyCarousel> {
  late final PageController _controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rabbitById = {for (final rabbit in widget.rabbits) rabbit.id: rabbit};
    return SizedBox(
      height: 224,
      child: PageView.builder(
        itemCount: widget.rabbits.length,
        controller: _controller,
        itemBuilder: (context, index) {
          final rabbit = widget.rabbits[index];
          final mother = rabbit.motherId == null
              ? null
              : rabbitById[rabbit.motherId];
          final path = rabbit.mainPhotoPath;
          final photo = path == null ? null : File(path);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.onOpenRabbit(rabbit),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photo != null && photo.existsSync())
                      Image.file(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _CarouselPlaceholder(),
                      )
                    else
                      const _CarouselPlaceholder(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xD9000000)],
                          stops: [0.28, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rabbit.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  mother == null
                                      ? 'Mother not recorded'
                                      : 'Mother: ${mother.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          if (mother?.mainPhotoPath != null) ...[
                            const SizedBox(width: 10),
                            RabbitAvatar(
                              path: mother!.mainPhotoPath,
                              size: 44,
                              iconSize: 20,
                            ),
                          ],
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CarouselPlaceholder extends StatelessWidget {
  const _CarouselPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Center(
      child: Icon(
        Icons.cruelty_free_rounded,
        size: 72,
        color: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
    ),
  );
}

class _KindlingAlert extends StatelessWidget {
  const _KindlingAlert({required this.record, required this.doe});

  final BreedingRecord record;
  final Rabbit? doe;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = DateUtils.dateOnly(
      record.estimatedKindlingDate,
    ).difference(DateUtils.dateOnly(today)).inDays;
    final message = days < 0
        ? '${days.abs()} days past typical date'
        : days == 0
        ? 'Typical date is today'
        : '$days days until typical date';
    final dateFormat = DateFormat.MMMd();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.event_available_outlined),
        ),
        title: Text('${doe?.name ?? 'Doe'} · $message'),
        subtitle: Text(
          'Estimated window ${dateFormat.format(record.estimatedKindlingStart)}–${dateFormat.format(record.estimatedKindlingEnd)}',
        ),
      ),
    );
  }
}

class _HerdBanner extends StatelessWidget {
  const _HerdBanner({required this.total, required this.onTap});

  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primary,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL RABBITS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View herd',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.cruelty_free_rounded,
              size: 62,
              color: Color(0x99FFFFFF),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.tint,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: tint),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  color: tint,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class EventsPlaceholder extends StatelessWidget {
  const EventsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    title: 'Events are coming next',
    message:
        'Breeding, pregnancy, and litter events will appear here in Part 2.',
  );
}
