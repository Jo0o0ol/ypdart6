import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../core/services.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  PageResult<Loan>? _loans;
  List<Reader> _readers = <Reader>[];
  List<Book> _books = <Book>[];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _readerId;
  int? _bookId;
  int _days = 14;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loans = await widget.services.loans.find();
      final readers = await widget.services.readers.find(
        const SimpleQuery(size: 100, sort: 'fullName,asc'),
      );
      final books = await widget.services.books.find(
        const BookQuery(size: 100, sort: 'title,asc'),
      );

      if (!mounted) return;
      setState(() {
        _loans = loans;
        _readers = readers.items;
        _books = books.items;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createLoan() async {
    if (_readerId == null || _bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите читателя и книгу.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.services.loans.create(
        readerId: _readerId!,
        bookId: _bookId!,
        days: _days,
      );
      await _load();
    } on ConflictException catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Конфликт 409'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _returnLoan(int id) async {
    try {
      await widget.services.loans.returnLoan(id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(services: widget.services, title: 'Выдачи книг'),
      body: PageFrame(
        child: _loading && _loans == null
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 650;
                      return Column(
                        children: [
                          _buildForm(compact, constraints.maxWidth),
                          const SizedBox(height: 12),
                          Expanded(
                            child: compact
                                ? _buildCards()
                                : _buildRows(),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildForm(bool compact, double maxWidth) {
    final full = compact ? maxWidth : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: full ?? 260,
              child: DropdownButtonFormField<int>(
                value: _readerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Читатель',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final r in _readers)
                    DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        r.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _readerId = value),
              ),
            ),
            SizedBox(
              width: full ?? 300,
              child: DropdownButtonFormField<int>(
                value: _bookId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Книга',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final b in _books)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text(
                        '${b.title} (доступно ${b.copiesAvailable})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _bookId = value),
              ),
            ),
            SizedBox(
              width: compact ? maxWidth : 120,
              child: DropdownButtonFormField<int>(
                value: _days,
                decoration: const InputDecoration(
                  labelText: 'Дней',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7')),
                  DropdownMenuItem(value: 14, child: Text('14')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _days = value);
                },
              ),
            ),
            SizedBox(
              width: compact ? maxWidth : null,
              child: FilledButton.icon(
                onPressed: _saving ? null : _createLoan,
                icon: const Icon(Icons.add),
                label: const Text('Выдать'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRows() {
    return ListView.separated(
      itemCount: _loans?.items.length ?? 0,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final loan = _loans!.items[index];
        return ListTile(
          title: Text(
            '${loan.bookTitle} → ${loan.readerName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Статус: ${loan.status} · до ${_date(loan.dueAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: loan.status == 'returned'
              ? const Icon(Icons.check_circle_outline)
              : FilledButton.tonal(
                  onPressed: () => _returnLoan(loan.id),
                  child: const Text('Вернуть'),
                ),
        );
      },
    );
  }

  Widget _buildCards() {
    return ListView.separated(
      itemCount: _loans?.items.length ?? 0,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final loan = _loans!.items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.bookTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Читатель: ${loan.readerName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('Статус: ${loan.status} · до ${_date(loan.dueAt)}'),
                const SizedBox(height: 10),
                if (loan.status == 'returned')
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.check_circle_outline),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => _returnLoan(loan.id),
                      child: const Text('Вернуть'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}
