import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../core/roles.dart';
import '../core/services.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

typedef ItemTitle<T> = String Function(T item);
typedef ItemSubtitle<T> = String Function(T item);
typedef ItemId<T> = int Function(T item);
typedef IsDeleted<T> = bool Function(T item);
typedef EditEntity<T> = Future<bool> Function(BuildContext context, T? item);

class SimpleResourceScreen<T> extends StatefulWidget {
  const SimpleResourceScreen({
    super.key,
    required this.services,
    required this.title,
    required this.repository,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.itemId,
    required this.isDeleted,
    required this.sortOptions,
    required this.editEntity,
  });

  final AppServices services;
  final String title;
  final ApiCrudRepository<T> repository;
  final ItemTitle<T> itemTitle;
  final ItemSubtitle<T> itemSubtitle;
  final ItemId<T> itemId;
  final IsDeleted<T> isDeleted;
  final Map<String, String> sortOptions;
  final EditEntity<T> editEntity;

  @override
  State<SimpleResourceScreen<T>> createState() =>
      _SimpleResourceScreenState<T>();
}

class _SimpleResourceScreenState<T> extends State<SimpleResourceScreen<T>> {
  final _search = TextEditingController();
  Timer? _debounce;
  late SimpleQuery _query;
  PageResult<T>? _page;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query = SimpleQuery(sort: widget.sortOptions.keys.first);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await widget.repository.find(_query);
      if (!mounted) return;
      setState(() => _page = page);
    } on CancelledRequestException {
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _query = _query.copyWith(search: value);
      _load();
    });
  }

  Future<void> _action(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _edit(T? item) async {
    final changed = await widget.editEntity(context, item);
    if (changed) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(services: widget.services, title: widget.title),
      floatingActionButton: widget.services.auth.uiHasAtLeast(AppRole.librarian)
          ? FloatingActionButton.extended(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          : null,
      body: PageFrame(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: compact ? constraints.maxWidth : 320,
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          labelText: 'Поиск на сервере',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _onSearch,
                      ),
                    ),
                    SizedBox(
                      width: compact ? constraints.maxWidth : 250,
                      child: DropdownButtonFormField<String>(
                        value: _query.sort,
                        decoration: const InputDecoration(
                          labelText: 'Сортировка',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final entry in widget.sortOptions.entries)
                            DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _query = _query.copyWith(sort: value);
                          _load();
                        },
                      ),
                    ),
                    if (widget.services.auth.uiHasAtLeast(AppRole.admin))
                      FilterChip(
                        selected: _query.includeDeleted,
                        label: const Text('Показывать удалённые'),
                        onSelected: (value) {
                          _query = _query.copyWith(includeDeleted: value);
                          _load();
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _page == null) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final page = _page;
    if (page == null || page.items.isEmpty) return const EmptyView();

    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: ResponsiveEntityLayout(
            cards: _cards(page.items),
            table: _table(page.items),
          ),
        ),
        PaginationBar(
          page: page.page,
          totalPages: page.totalPages,
          total: page.total,
          size: page.size,
          onPageChanged: (value) {
            _query = _query.copyWith(page: value);
            _load();
          },
          onSizeChanged: (value) {
            _query = _query.copyWith(size: value);
            _load();
          },
        ),
      ],
    );
  }

  Widget _cards(List<T> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final deleted = widget.isDeleted(item);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemTitle(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: deleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.itemSubtitle(item),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_actions(item).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 4, children: _actions(item)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _table(List<T> items) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Название')),
            DataColumn(label: Text('Описание')),
            DataColumn(label: Text('Действия')),
          ],
          rows: [
            for (final item in items)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(
                        widget.itemTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: widget.isDeleted(item)
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 360,
                      child: Text(
                        widget.itemSubtitle(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Wrap(spacing: 2, children: _actions(item))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(T item) {
    final id = widget.itemId(item);
    final deleted = widget.isDeleted(item);

    return [
      if (!deleted && widget.services.auth.uiHasAtLeast(AppRole.librarian))
        IconButton(
          tooltip: 'Редактировать',
          onPressed: () => _edit(item),
          icon: const Icon(Icons.edit_outlined),
        ),
      if (!deleted && widget.services.auth.uiHasAtLeast(AppRole.librarian))
        IconButton(
          tooltip: 'Логически удалить',
          onPressed: () => _action(() => widget.repository.softDelete(id)),
          icon: const Icon(Icons.delete_outline),
        ),
      if (deleted && widget.services.auth.uiHasAtLeast(AppRole.admin))
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () => _action(() async {
            await widget.repository.restore(id);
          }),
          icon: const Icon(Icons.restore),
        ),
      if (deleted && widget.services.auth.uiHasAtLeast(AppRole.admin))
        IconButton(
          tooltip: 'Удалить физически',
          onPressed: () => _action(() => widget.repository.hardDelete(id)),
          icon: const Icon(Icons.delete_forever),
        ),
    ];
  }
}
