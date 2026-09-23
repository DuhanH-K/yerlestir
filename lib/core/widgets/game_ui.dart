import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/progress/progress.dart';
import '../services/storage_status.dart';
import 'skin_style.dart';
import 'ad_banner.dart';

export 'fit_page.dart';

part 'gloss_button.dart';

const ink = Color(0xff174a72);
const blue = Color(0xff13aaff);
const green = Color(0xff0dc569);
const purple = Color(0xff9250ed);
const coral = Color(0xffff7367);
String tr(WidgetRef ref, String turkish, String english) =>
    ref.watch(progressProvider).localeCode == 'tr' ? turkish : english;
String number(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);

class GameShell extends ConsumerWidget {
  const GameShell({
    super.key,
    required this.child,
    this.back = true,
    this.toolbar = true,
  });
  final Widget child;
  final bool back, toolbar;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    return Scaffold(
      bottomNavigationBar: toolbar ? const GameBanner() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff74d6ff), Color(0xff087fa9)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (p.selectedSkin != 'default')
                  SkinBackdrop(skin: p.selectedSkin),
                if (p.selectedSkin == 'default')
                  Image.asset(
                    'assets/backgrounds/coast.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => const SizedBox(),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x100ba8ff),
                        Color(0x00ffffff),
                        Color(0x44fff1d8),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      if (toolbar)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Row(
                            children: [
                              if (back)
                                IconButton.filled(
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go('/'),
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 32,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: ink,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                const CircleAvatar(
                                  radius: 23,
                                  backgroundColor: Color(0xfffbebd3),
                                  child: Text(
                                    '🐱',
                                    style: TextStyle(fontSize: 29),
                                  ),
                                ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ink.withValues(alpha: .9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white38,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on_rounded,
                                      color: Color(0xffffd02c),
                                      size: 27,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      number(p.coins),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                tooltip: tr(ref, 'Ayarlar', 'Settings'),
                                onPressed: () => context.push('/settings'),
                                icon: const Icon(Icons.settings_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: ink,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!ref.watch(storageStatusProvider))
                        Container(
                          width: double.infinity,
                          color: Colors.amber.shade100,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            tr(
                              ref,
                              'Kayıt yapılamadı. Cihazında yer aç; sonraki hamlede yeniden denenecek.',
                              'Could not save. Free device storage; your next move retries saving.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameTitle extends StatelessWidget {
  const GameTitle(this.title, {super.key, this.subtitle, this.size = 58});
  final String title;
  final String? subtitle;
  final double size;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (title == 'Yerleştir!')
        Image.asset(
          'assets/backgrounds/logo.png',
          width: size * 5,
          height: size * 2.15,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stack) => Text(
            title,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              color: Colors.amber,
            ),
          ),
        )
      else
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 10
                    ..color = const Color(0xff06446e),
                  shadows: const [
                    Shadow(
                      color: Color(0xff002c4b),
                      offset: Offset(0, 7),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  color: const Color(0xffffd43e),
                  shadows: const [
                    Shadow(color: Color(0xffe67f16), offset: Offset(0, 3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (subtitle != null)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xffffedd1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x448b5525), offset: Offset(0, 3)),
            ],
          ),
          child: Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ],
  );
}

class CreamPanel extends StatelessWidget {
  const CreamPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xfffffaf0), Color(0xfff5dfc0)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xfffffff3), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44864f25),
          offset: Offset(0, 5),
          blurRadius: 7,
        ),
      ],
    ),
    child: child,
  );
}

class FooterNote extends StatelessWidget {
  const FooterNote({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Düşün • Yerleştir • Rahatla!  ♡',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ink,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
