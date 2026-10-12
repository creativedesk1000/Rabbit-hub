import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/rabbit.dart';
import '../widgets/rabbit_widgets.dart';

class RabbitListScreen extends StatefulWidget {
  const RabbitListScreen({
    super.key,
    required this.onOpenRabbit,
    required this.onAddRabbit,
  });

  final ValueChanged<Rabbit> onOpenRabbit;
  final VoidCallback onAddRabbit;

  @override
  State<RabbitListScreen> createState() => _RabbitListScreenState();
}

class _RabbitListScreenState extends State<RabbitListScreen> {
  final _search = TextEditingController();
  List<Rabbit> _rabbits = [];
  String _filter = 'All';

  static const _filters = [
    'All',
    'Male',
    'Female',
    'Active',
    'Sick',
    'Pregnant',
    'Nursing',
    'Retired',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await AppDatabase.instance.rabbits();
    if (mounted) setState(() => _rabbits = rows.map(Rabbit.fromMap).toList());
  }

  List<Rabbit> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _rabbits.where((rabbit) {
      final matchesText =
          query.isEmpty ||
          [
            rabbit.name,
            rabbit.rabbitId,
            rabbit.earTag,
            rabbit.breed,
            rabbit.color,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
      final matchesFilter = switch (_filter) {
        'Male' || 'Female' => rabbit.gender == _filter,
        _ =>
          _filter == 'All' ||
              rabbit.status == _filter ||
              (_filter == 'Sick' && rabbit.status == 'Under Treatment'),
      };
      return matchesText && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabbits'),
        actions: [
          IconButton(
            onPressed: widget.onAddRabbit,
            tooltip: 'Add rabbit',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Name, ID, ear tag, breed, color',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _search.clear,
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    title: _rabbits.isEmpty
                        ? 'No rabbits yet'
                        : 'No matches found',
                    message: _rabbits.isEmpty
                        ? 'Create a profile to start your herd records.'
                        : 'Try another search or filter.',
                    action: _rabbits.isEmpty ? 'Add rabbit' : null,
                    onAction: widget.onAddRabbit,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _RabbitCard(
                        rabbit: visible[index],
                        onTap: () => widget.onOpenRabbit(visible[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RabbitCard extends StatelessWidget {
  const _RabbitCard({required this.rabbit, required this.onTap});

  final Rabbit rabbit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            RabbitAvatar(path: rabbit.mainPhotoPath, size: 68, iconSize: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rabbit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      StatusBadge(status: rabbit.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rabbit.rabbitId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      rabbit.gender,
                      rabbit.breed,
                    ].where((value) => value?.isNotEmpty == true).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rabbit.ageLabel}  ·  ${rabbit.weight == null ? 'Weight not recorded' : '${rabbit.weight} ${rabbit.weightUnit}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
