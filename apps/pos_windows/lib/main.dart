import 'package:core_domain/core_domain.dart';
import 'package:flutter/material.dart';

void main() => runApp(const PosApp());

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Apparel PoS (core $coreDomainSkeletonVersion)')),
      ),
    );
  }
}
