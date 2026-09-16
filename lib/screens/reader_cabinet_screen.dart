import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../core/services.dart';
import '../models/models.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';

class ReaderCabinetScreen extends StatefulWidget {
  const ReaderCabinetScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<ReaderCabinetScreen> createState() => _ReaderCabinetScreenState();
}

class _ReaderCabinetScreenState extends State<ReaderCabinetScreen> {
  PageResult<Loan>? _loans;
  bool _loading = true;
  String? _error;

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
      final result = await widget.services.loans.find();
      if (!mounted) return;
      setState(() => _loans = result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _extend(int id) async {
    try {
      await widget.services.loans.extendLoan(id, days: 7);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Срок выдачи продлён на 7 дней.')),
      );
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
      appBar: AppTopBar(
        services: widget.services,
        title: 'Кабинет читателя',
      ),
      body: PageFrame(
        child: _loading && _loans == null
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Здесь видны только собственные выдачи. '
                            'Активную выдачу можно продлить на 7 дней.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: (_loans?.items.isEmpty ?? true)
                            ? const EmptyView()
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 600;
                                  return compact
                                      ? _cards()
                                      : _rows();
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _rows() {
    return ListView.separated(
      itemCount: _loans!.items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final loan = _loans!.items[index];
        return ListTile(
          title: Text(
            loan.bookTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Статус: ${loan.status} · до ${_date(loan.dueAt)}',
          ),
          trailing: loan.returnedAt == null
              ? FilledButton.tonalIcon(
                  onPressed: () => _extend(loan.id),
                  icon: const Icon(Icons.update),
                  label: const Text('Продлить'),
                )
              : const Icon(Icons.check_circle_outline),
        );
      },
    );
  }

  Widget _cards() {
    return ListView.separated(
      itemCount: _loans!.items.length,
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
                const SizedBox(height: 6),
                Text('Статус: ${loan.status}'),
                Text('Срок: до ${_date(loan.dueAt)}'),
                const SizedBox(height: 10),
                if (loan.returnedAt == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _extend(loan.id),
                      icon: const Icon(Icons.update),
                      label: const Text('Продлить'),
                    ),
                  )
                else
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.check_circle_outline),
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
