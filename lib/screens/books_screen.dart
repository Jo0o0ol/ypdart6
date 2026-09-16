import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../core/roles.dart';
import '../core/services.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({
    super.key,
    required this.services,
    this.initialDelay,
    this.initialFail,
  });

  final AppServices services;
  final int? initialDelay;
  final int? initialFail;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _search = TextEditingController();
  final _yearFrom = TextEditingController();
  final _yearTo = TextEditingController();
  Timer? _debounce;

  late BookQuery _query;
  PageResult<Book>? _page;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query = BookQuery(
      delayMs: widget.initialDelay,
      failCode: widget.initialFail,
    );
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _yearFrom.dispose();
    _yearTo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.services.books.find(_query);
      if (!mounted) return;
      setState(() => _page = result);
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

  void _applyYears() {
    _query = _query.copyWith(
      yearFrom: int.tryParse(_yearFrom.text.trim()),
      yearTo: int.tryParse(_yearTo.text.trim()),
      clearYearFrom: _yearFrom.text.trim().isEmpty,
      clearYearTo: _yearTo.text.trim().isEmpty,
    );
    _load();
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

  Future<void> _edit(Book? book) async {
    final changed = await showBookFormDialog(context, widget.services, book);
    if (changed) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        services: widget.services,
        title: 'Каталог книг',
      ),
      floatingActionButton: widget.services.auth.uiHasAtLeast(AppRole.librarian)
          ? FloatingActionButton.extended(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Новая книга'),
            )
          : null,
      body: PageFrame(
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final full = compact ? constraints.maxWidth : 330.0;
        final half = compact
            ? math.max(120.0, (constraints.maxWidth - 10) / 2)
            : 130.0;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: full,
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Поиск по названию или ISBN',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearch,
              ),
            ),
            SizedBox(
              width: half,
              child: TextField(
                controller: _yearFrom,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Год от',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: TextField(
                controller: _yearTo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Год до',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _applyYears,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Применить'),
            ),
            SizedBox(
              width: compact ? constraints.maxWidth : 210,
              child: DropdownButtonFormField<String>(
                value: _query.sort,
                decoration: const InputDecoration(
                  labelText: 'Сортировка',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'title,asc', child: Text('Название ↑')),
                  DropdownMenuItem(value: 'title,desc', child: Text('Название ↓')),
                  DropdownMenuItem(value: 'year,asc', child: Text('Год ↑')),
                  DropdownMenuItem(value: 'year,desc', child: Text('Год ↓')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _query = _query.copyWith(sort: value);
                  _load();
                },
              ),
            ),
            FilterChip(
              selected: _query.available == true,
              label: const Text('Только доступные'),
              onSelected: (value) {
                _query = _query.copyWith(
                  available: value ? true : null,
                  clearAvailable: !value,
                );
                _load();
              },
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
            cards: _buildCards(page.items),
            table: _buildTable(page.items),
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

  Widget _buildCards(List<Book> books) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: book.isDeleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${book.isbn} · ${book.year} · ${book.publisherName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('Доступно: ${book.copiesAvailable}/${book.copiesTotal}'),
                if (_bookActions(book).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 4, children: _bookActions(book)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(List<Book> books) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Название')),
            DataColumn(label: Text('ISBN')),
            DataColumn(label: Text('Год')),
            DataColumn(label: Text('Издательство')),
            DataColumn(label: Text('Доступно')),
            DataColumn(label: Text('Действия')),
          ],
          rows: [
            for (final book in books)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 260,
                      child: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: book.isDeleted
                            ? const TextStyle(decoration: TextDecoration.lineThrough)
                            : null,
                      ),
                    ),
                  ),
                  DataCell(Text(book.isbn)),
                  DataCell(Text('${book.year}')),
                  DataCell(Text(book.publisherName)),
                  DataCell(Text('${book.copiesAvailable}/${book.copiesTotal}')),
                  DataCell(Wrap(spacing: 2, children: _bookActions(book))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bookActions(Book book) {
    return [
      if (!book.isDeleted &&
          widget.services.auth.uiHasAtLeast(AppRole.librarian))
        IconButton(
          tooltip: 'Редактировать',
          onPressed: () => _edit(book),
          icon: const Icon(Icons.edit_outlined),
        ),
      if (!book.isDeleted &&
          widget.services.auth.uiHasAtLeast(AppRole.librarian))
        IconButton(
          tooltip: 'Логически удалить',
          onPressed: () => _action(
            () => widget.services.books.softDelete(book.id),
          ),
          icon: const Icon(Icons.delete_outline),
        ),
      if (book.isDeleted && widget.services.auth.uiHasAtLeast(AppRole.admin))
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () => _action(() async {
            await widget.services.books.restore(book.id);
          }),
          icon: const Icon(Icons.restore),
        ),
      if (book.isDeleted && widget.services.auth.uiHasAtLeast(AppRole.admin))
        IconButton(
          tooltip: 'Удалить физически',
          onPressed: () => _action(
            () => widget.services.books.hardDelete(book.id),
          ),
          icon: const Icon(Icons.delete_forever),
        ),
    ];
  }
}

Future<bool> showBookFormDialog(
  BuildContext context,
  AppServices services,
  Book? existing,
) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final isbn = TextEditingController(text: existing?.isbn ?? '');
  final year = TextEditingController(text: existing?.year.toString() ?? '');
  final pages = TextEditingController(text: existing?.pages.toString() ?? '');
  final copies = TextEditingController(text: existing?.copiesTotal.toString() ?? '');
  final formKey = GlobalKey<FormState>();

  var publishers = <Publisher>[];
  var authors = <Author>[];
  var genres = <Genre>[];
  var publisherId = existing?.publisherId;
  var authorIds = <int>[...?existing?.authorIds];
  var genreIds = <int>[...?existing?.genreIds];
  var loading = true;
  var saving = false;
  var serverErrors = <String, String>{};
  String? loadError;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (loading) {
            Future<void>(() async {
              try {
                final values = await Future.wait([
                  services.references.publishers(),
                  services.references.authors(),
                  services.references.genres(),
                ]);
                publishers = values[0] as List<Publisher>;
                authors = values[1] as List<Author>;
                genres = values[2] as List<Genre>;
              } on ApiException catch (e) {
                loadError = e.message;
              } finally {
                if (context.mounted) setState(() => loading = false);
              }
            });
          }

          String? requiredField(String? value, String field) {
            final server = serverErrors[field];
            if (server != null) return server;
            if (value == null || value.trim().isEmpty) return 'Обязательное поле';
            return null;
          }

          String? intField(String? value, String field, int min) {
            final server = serverErrors[field];
            if (server != null) return server;
            final parsed = int.tryParse(value?.trim() ?? '');
            if (parsed == null) return 'Введите целое число';
            if (parsed < min) return 'Минимум $min';
            return null;
          }

          Future<void> save() async {
            setState(() => serverErrors = <String, String>{});
            if (!formKey.currentState!.validate()) return;
            if (publisherId == null || authorIds.isEmpty || genreIds.isEmpty) {
              setState(() {});
              return;
            }
            setState(() => saving = true);

            final book = Book(
              id: existing?.id ?? 0,
              title: title.text.trim(),
              isbn: isbn.text.trim(),
              year: int.parse(year.text.trim()),
              pages: int.parse(pages.text.trim()),
              publisherId: publisherId,
              publisherName: '',
              authorIds: authorIds,
              authorNames: const [],
              genreIds: genreIds,
              genreNames: const [],
              copiesTotal: int.parse(copies.text.trim()),
              copiesAvailable: existing?.copiesAvailable ?? 0,
            );

            try {
              if (existing == null) {
                await services.books.create(book);
              } else {
                await services.books.update(book);
              }
              if (context.mounted) Navigator.pop(context, true);
            } on ValidationException catch (e) {
              setState(() => serverErrors = e.errors);
              formKey.currentState!.validate();
            } on ApiException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
            } finally {
              if (context.mounted) setState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(existing == null ? 'Новая книга' : 'Редактирование книги'),
            content: SizedBox(
              width: math.min(760.0, math.max(260.0, MediaQuery.sizeOf(context).width - 48.0)),
              child: loading
                  ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
                  : loadError != null
                      ? Text(loadError!)
                      : SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: title,
                                  decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                                  validator: (value) => requiredField(value, 'title'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: isbn,
                                  decoration: const InputDecoration(labelText: 'ISBN', border: OutlineInputBorder()),
                                  validator: (value) => requiredField(value, 'isbn'),
                                ),
                                const SizedBox(height: 10),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final compact = constraints.maxWidth < 420;
                                    final fieldWidth = compact
                                        ? constraints.maxWidth
                                        : (constraints.maxWidth - 10) / 2;
                                    return Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        SizedBox(
                                          width: fieldWidth,
                                          child: TextFormField(
                                            controller: year,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Год',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (value) => intField(value, 'year', 1450),
                                          ),
                                        ),
                                        SizedBox(
                                          width: fieldWidth,
                                          child: TextFormField(
                                            controller: pages,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Страниц',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator: (value) => intField(value, 'pages', 1),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<int>(
                                  value: publisherId,
                                  decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
                                  items: [
                                    for (final p in publishers) DropdownMenuItem(value: p.id, child: Text(p.name)),
                                  ],
                                  onChanged: (value) => setState(() => publisherId = value),
                                  validator: (value) {
                                    final server = serverErrors['publisherId'];
                                    if (server != null) return server;
                                    return value == null ? 'Выберите издательство' : null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Авторы',
                                    border: const OutlineInputBorder(),
                                    errorText: authorIds.isEmpty ? 'Выберите хотя бы одного автора' : serverErrors['authorIds'],
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      for (final a in authors)
                                        FilterChip(
                                          label: Text(a.fullName),
                                          selected: authorIds.contains(a.id),
                                          onSelected: (_) {
                                            setState(() {
                                              if (authorIds.contains(a.id)) {
                                                authorIds.remove(a.id);
                                              } else {
                                                authorIds.add(a.id);
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Жанры',
                                    border: const OutlineInputBorder(),
                                    errorText: genreIds.isEmpty ? 'Выберите хотя бы один жанр' : serverErrors['genreIds'],
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      for (final g in genres)
                                        FilterChip(
                                          label: Text(g.name),
                                          selected: genreIds.contains(g.id),
                                          onSelected: (_) {
                                            setState(() {
                                              if (genreIds.contains(g.id)) {
                                                genreIds.remove(g.id);
                                              } else {
                                                genreIds.add(g.id);
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: copies,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Всего экземпляров', border: OutlineInputBorder()),
                                  validator: (value) => intField(value, 'copiesTotal', 0),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Отмена')),
              FilledButton(onPressed: loading || saving || loadError != null ? null : save, child: const Text('Сохранить')),
            ],
          );
        },
      );
    },
  );

  title.dispose();
  isbn.dispose();
  year.dispose();
  pages.dispose();
  copies.dispose();
  return result == true;
}
