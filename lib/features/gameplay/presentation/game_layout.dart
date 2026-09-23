part of 'game_screen.dart';

extension _GameLayout on _GameScreenState {
  Widget buildGame(BuildContext context) {
    final p = ref.watch(progressProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) pause();
      },
      child: Scaffold(
        bottomNavigationBar: const GameBanner(),
        backgroundColor: const Color(0xff294578),
        body: SkinBackdrop(
          skin: p.selectedSkin,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ShakeFeedback(
                  trigger: rejections,
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      // Reserve controls first; the square board never pushes the tray off-screen.
                      final compact = bounds.maxHeight < 640;
                      final header = compact ? 98.0 : 132.0;
                      final trayHeight = compact ? 96.0 : 120.0;
                      final side = (bounds.maxHeight - header - trayHeight - 94)
                          .clamp(80.0, bounds.maxWidth - 24);
                      final cell = (side - boardInset * 2) / boardSize;
                      return Column(
                        children: [
                          SizedBox(
                            height: header,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 44,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.emoji_events_rounded,
                                          color: Color(0xffffd45a),
                                          size: 28,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          number(
                                            game.score > p.highScore
                                                ? game.score
                                                : p.highScore,
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xffffd45a),
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: tr(ref, 'Duraklat', 'Pause'),
                                          onPressed: pause,
                                          icon: const Icon(
                                            Icons.pause_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: LiveScore(
                                        score: game.score,
                                        best: p.highScore,
                                        compact: compact,
                                        english: p.localeCode == 'en',
                                      ),
                                    ),
                                  ),
                                  if (game.mode != GameMode.classic)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        '${game.mode == GameMode.daily ? tr(ref, 'Günlük', 'Daily') : tr(ref, 'Bölüm ${game.level}', 'Level ${game.level}')}  •  ${game.score}/${game.target}  •  ${game.moveLimit - game.moves} ${tr(ref, 'hamle', 'moves')}',
                                        style: const TextStyle(
                                          color: Color(0xffd2e6ff),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: side,
                            height: side,
                            child: Stack(
                              children: [
                                RepaintBoundary(
                                  child: AbsorbPointer(
                                    absorbing:
                                        starting ||
                                        animating ||
                                        purchasing ||
                                        busy,
                                    child: BoardView(
                                      game: game,
                                      selected: selected,
                                      skin: p.selectedSkin,
                                      hint: hint,
                                      onDrop: drop,
                                    ),
                                  ),
                                ),
                                if (starting)
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(boardInset),
                                      child: BoardIntro(
                                        onEnd: () {
                                          if (mounted) {
                                            updateUi(() => starting = false);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                if (animating)
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(boardInset),
                                      child: LineBurst(
                                        key: ValueKey(game.moves),
                                        cells: game.lastClearedCells,
                                        points: game.lastScoreGain,
                                        message: celebration,
                                        detail: scoreDetail,
                                      ),
                                    ),
                                  ),
                                if (!animating && showGain)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Center(
                                        child: TweenAnimationBuilder<double>(
                                          key: ValueKey(game.moves),
                                          tween: Tween(begin: 0, end: 1),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          builder: (_, t, child) =>
                                              Transform.translate(
                                                offset: Offset(0, -28 * t),
                                                child: Opacity(
                                                  opacity: (1 - t).clamp(0, 1),
                                                  child: Text(
                                                    '+${game.lastScoreGain}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 28,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black54,
                                                          blurRadius: 7,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 28,
                            child: Center(
                              child: Text(
                                hintNotice ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xffffdc77),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: SizedBox(
                                height: trayHeight,
                                child: AbsorbPointer(
                                  absorbing: starting || busy || purchasing,
                                  child: PieceTray(
                                    game: game,
                                    selected: selected,
                                    skin: p.selectedSkin,
                                    boardCell: cell,
                                    height: trayHeight,
                                    onSelected: (i) => updateUi(() {
                                      selected = i;
                                      hint = null;
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 3,
                            ),
                            child: Container(
                              height: 58,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff213d68),
                                    Color(0xff172e51),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xff58749b),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33051024),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    key: const ValueKey('hint-lamp'),
                                    onPressed:
                                        starting ||
                                            busy ||
                                            animating ||
                                            purchasing ||
                                            hint != null
                                        ? null
                                        : purchaseHint,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xffffdb78),
                                      disabledForegroundColor: const Color(
                                        0xff92a2b9,
                                      ),
                                      minimumSize: const Size(110, 48),
                                    ),
                                    icon: Icon(
                                      hint != null
                                          ? Icons.check_rounded
                                          : Icons.lightbulb_rounded,
                                      size: 28,
                                    ),
                                    label: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr(ref, 'İpucu', 'Hint'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          tr(ref, '30 altın', '30 coins'),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 1,
                                    height: 26,
                                    color: const Color(0xff58749b),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    size: 24,
                                    color: Color(0xffffd45a),
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: FittedBox(
                                      child: Text(
                                        number(p.coins),
                                        style: const TextStyle(
                                          color: Color(0xffffe8a8),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
