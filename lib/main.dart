import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: GiftExchangeApp()));
}

class GiftExchangeApp extends ConsumerWidget {
  const GiftExchangeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'The Gift Exchange Global',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
