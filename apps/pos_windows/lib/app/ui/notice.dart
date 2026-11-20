import 'package:flutter/material.dart';

import '../build_info.dart';

/// The line shown on every sign-in screen until the database is encrypted.
class EncryptionNotice extends StatelessWidget {
  const EncryptionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (databaseEncrypted) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'Development build: the database is not encrypted yet. Do not enter real shop data.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
