import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services.dart';

class SessionWatcher extends StatefulWidget {
  const SessionWatcher({
    super.key,
    required this.services,
    required this.child,
  });

  final AppServices services;
  final Widget child;

  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    widget.services.auth.noteActivity();
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.services.auth.noteActivity(),
      onPointerMove: (_) => widget.services.auth.noteActivity(),
      onPointerSignal: (_) => widget.services.auth.noteActivity(),
      child: AnimatedBuilder(
        animation: widget.services.auth,
        builder: (context, _) {
          final seconds = widget.services.auth.inactivitySecondsLeft;
          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (seconds != null)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: SafeArea(
                    bottom: false,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 520;
                            final message = Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.timer_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Сессия завершится через $seconds сек. из-за неактивности.',
                                  ),
                                ),
                              ],
                            );

                            final button = FilledButton(
                              onPressed: widget.services.auth.noteActivity,
                              child: const Text('Продолжить работу'),
                            );

                            if (compact) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  message,
                                  const SizedBox(height: 10),
                                  button,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: message),
                                const SizedBox(width: 12),
                                button,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
