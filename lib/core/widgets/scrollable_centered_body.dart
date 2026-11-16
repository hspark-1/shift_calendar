// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';

/// 기존 CustomScrollView 안에서 빈 목록·오류 안내를 가운데 배치한다.
class SliverCenteredBody extends StatelessWidget {
  const SliverCenteredBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    ),
  );
}
