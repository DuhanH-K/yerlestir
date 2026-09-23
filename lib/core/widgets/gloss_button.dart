part of 'game_ui.dart';

class GlossButton extends StatefulWidget {
  const GlossButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = blue,
    this.subtitle,
    this.height = 66,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final String? subtitle;
  final double height;
  @override
  State<GlossButton> createState() => _GlossButtonState();
}

class _GlossButtonState extends State<GlossButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      child: AnimatedScale(
        scale: pressed ? .96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: widget.onTap == null ? .55 : 1,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, .32)!,
                  color,
                  Color.lerp(color, Colors.black, .13)!,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .8),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(color, Colors.black, .35)!,
                  offset: Offset(0, pressed ? 1 : 4),
                ),
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => pressed = v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: widget.height > 75 ? 38 : 24,
                          shadows: const [
                            Shadow(color: Colors.black26, offset: Offset(0, 2)),
                          ],
                        ),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: widget.height > 75 ? 29 : 18,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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
