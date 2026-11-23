import 'package:flutter/material.dart';

import '../build_info.dart';

/// The line shown on every sign-in screen when the database is not encrypted
/// (the browser preview). Hidden on desktop, where it always is.
class EncryptionNotice extends StatelessWidget {
  const EncryptionNotice({super.key, this.encrypted = databaseEncrypted});

  /// Whether the database in use is encrypted.
  final bool encrypted;

  @override
  Widget build(BuildContext context) {
    if (encrypted) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'Browser preview: nothing here is encrypted or kept. Do not enter real shop data.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
