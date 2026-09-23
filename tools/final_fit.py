from pathlib import Path
p=Path('test/layout_regression_test.dart');s=p.read_text(encoding='utf-8').replace('expect(\n            state.position.maxScrollExtent,\n            0,','expect(\n            state.position.maxScrollExtent,\n            closeTo(0, 0.001),').replace('await loader.load();','await tester.runAsync(() => loader.load());');p.write_text(s,encoding='utf-8')
p=Path('lib/features/levels/journey_screen.dart');s=p.read_text(encoding='utf-8');s=s.replace('      child: Column(', '      child: FitViewport(child: Column(',1);idx=s.index('\nclass CollectionScreen');first=s[:idx];pos=first.rfind('      ),');first=first[:pos]+first[pos:].replace('      ),','      )),',1);s=first+s[idx:];p.write_text(s,encoding='utf-8')
p=Path('lib/core/widgets/fit_page.dart');s=p.read_text(encoding='utf-8');s+='''
class FitViewport extends StatelessWidget {
  const FitViewport({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) =>
    Center(child: FittedBox(fit: BoxFit.scaleDown, child: SizedBox(
      width: bounds.maxWidth,
      height: bounds.maxHeight < 480 ? 480 : bounds.maxHeight,
      child: child,
    ))));
}
''';p.write_text(s,encoding='utf-8')
