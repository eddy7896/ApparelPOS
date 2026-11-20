import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

void main() => runApp(const PosApp());

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apparel PoS (core $coreDomainSkeletonVersion)'),
              // The browser build is for development only (ADR-0016): no
              // encrypted database and no hardware, so never use it in the shop.
              if (kIsWeb)
                const Text('Web preview: development only, not for the shop'),
            ],
          ),
        ),
      ),
    );
  }
}
