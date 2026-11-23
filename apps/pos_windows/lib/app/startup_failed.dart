import 'package:flutter/material.dart';

/// Shown when the app cannot open its database at start-up, so the window is
/// never just blank.
class StartupFailedApp extends StatelessWidget {
  const StartupFailedApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Apparel PoS',
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The app could not start',
                  key: Key('startup-failed-title'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('The database could not be opened. Details:'),
                const SizedBox(height: 8),
                SelectableText(
                  error.toString(),
                  key: const Key('startup-failed-error'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
