import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/game_ui.dart';
import '../core/widgets/blocks.dart';
import '../features/home/home_screen.dart';
import '../features/levels/journey_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/daily_reward/reward_screen.dart';
import '../features/gameplay/domain/puzzle.dart';
import '../features/gameplay/presentation/game_screen.dart';
import '../features/gameplay/presentation/result_screen.dart';
import '../features/progress/progress.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (_, state) => const HomeScreen()),
      GoRoute(path: '/journey', builder: (_, state) => const JourneyScreen()),
      GoRoute(
        path: '/collection',
        builder: (_, state) => const CollectionScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, state) => const SettingsScreen()),
      GoRoute(path: '/shop', builder: (_, state) => const ShopScreen()),
      GoRoute(path: '/reward', builder: (_, state) => const RewardScreen()),
      GoRoute(
        path: '/game/:mode/:level',
        redirect: (_, state) {
          final level = int.tryParse(state.pathParameters['level'] ?? '');
          final mode = state.pathParameters['mode'];
          if (!GameMode.values.any((m) => m.name == mode) ||
              level == null ||
              level < 1 ||
              level > 120) {
            return '/';
          }
          if (mode == 'journey' &&
              level > 1 &&
              !ref
                  .read(progressProvider)
                  .levelStars
                  .containsKey('${level - 1}')) {
            return '/journey';
          }
          return null;
        },
        builder: (_, state) => GameScreen(
          key: ValueKey(state.uri.toString()),
          mode: GameMode.values.byName(state.pathParameters['mode']!),
          level: int.parse(state.pathParameters['level']!),
          fresh: state.uri.queryParameters['fresh'] == '1',
        ),
      ),
      GoRoute(
        path: '/result',
        builder: (_, state) => ResultScreen(
          result: state.extra is GameResult ? state.extra as GameResult : null,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class YerlestirApp extends ConsumerWidget {
  const YerlestirApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Yerleştir!',
    debugShowCheckedModeBanner: false,
    routerConfig: ref.watch(routerProvider),
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: const Color(0xff9edffc),
      fontFamily: 'Arial',
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xfffff2dc)),
      snackBarTheme: const SnackBarThemeData(backgroundColor: ink),
    ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameShell(
    toolbar: false,
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GameTitle(
                  'Yerleştir!',
                  subtitle: 'Küçük Hamleler, Büyük Keyif!',
                  size: 70,
                ),
                const SizedBox(height: 35),
                Transform.rotate(
                  angle: -.08,
                  child: const SizedBox(width: 230, child: DecorativeBoard()),
                ),
                const SizedBox(height: 90),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  builder: (_, value, child) => LinearProgressIndicator(
                    value: value,
                    color: const Color(0xffffd128),
                    backgroundColor: ink,
                    minHeight: 15,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yükleniyor…',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                ),
                const FooterNote(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
