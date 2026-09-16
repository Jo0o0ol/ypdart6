import 'package:flutter/material.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.maxWidth = 1300,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 600 ? 12.0 : 20.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: child,
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.text = 'Загрузка данных с сервера...',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 54),
            SizedBox(height: 12),
            Text(
              'По заданным условиям ничего не найдено.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 54,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  final int page;
  final int totalPages;
  final int total;
  final int size;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        IconButton(
          tooltip: 'Предыдущая страница',
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Страница $page из $totalPages · всего $total'),
        IconButton(
          tooltip: 'Следующая страница',
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
        const Text('На странице:'),
        DropdownButton<int>(
          value: size,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (value) {
            if (value != null) onSizeChanged(value);
          },
        ),
      ],
    );
  }
}
