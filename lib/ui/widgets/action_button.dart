import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final bool isLogged;
  const CustomFloatingActionButton({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      heroTag: 'my-logs-fab',
      onPressed: isLogged ? () {} : () => context.push('/logs/new'),
      label: Text(
        isLogged ? "ALREADY LOGGED" : "NEW LOG",
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      icon: Icon(isLogged ? Icons.check_circle_rounded : Icons.add_rounded),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 4,
    );
  }
}
