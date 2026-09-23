from pathlib import Path
p=Path('lib/features/settings/settings_screen.dart');s=p.read_text(encoding='utf-8')
a=s.index('          GameTitle(');b=s.index('          CreamPanel(',a)
s=s[:a]+"          GameTitle(tr(ref, 'Ayarlar', 'Settings'), size: 32),\n          const SizedBox(height: 6),\n"+s[b:]
p.write_text(s,encoding='utf-8')
p=Path('lib/features/shop/shop_screen.dart');s=p.read_text(encoding='utf-8')
s=s.replace('child: ListView(', 'child: LayoutBuilder(builder: (context, bounds) => ListView(',1)
s=s.replace('EdgeInsets.all(20)', 'EdgeInsets.all(8)')
s=s.replace("            subtitle: tr(ref, 'Oyununu renklendir!', 'Make the game your own!'),", '            size: 34,')
s=s.replace('height: 24','height: 8').replace('height: 20','height: 8').replace('height: 22','height: 8').replace('height: 10','height: 4')
s=s.replace('gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(', 'gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(')
s=s.replace('childAspectRatio: .62,','mainAxisExtent: ((bounds.maxHeight - 210) / 2).clamp(130.0, 300.0),')
s=s.replace('mainAxisSpacing: 16','mainAxisSpacing: 8').replace('height: 55','height: 48')
s=s.replace('          CreamPanel(\n            child: Text(', '          CreamPanel(\n            padding: const EdgeInsets.all(5),\n            child: Text(')
s=s.replace('              textAlign: TextAlign.center,','              textAlign: TextAlign.center,\n              style: const TextStyle(fontSize: 11),')
s=s.replace('          const FooterNote(),','')
s=s.replace('        ],\n      ),\n    );','        ],\n      )),\n    );')
p.write_text(s,encoding='utf-8')
p=Path('lib/features/levels/journey_screen.dart');s=p.read_text(encoding='utf-8')
s=s.replace("tr(ref, 'Yolculuk', 'Journey'),", "tr(ref, 'Yolculuk', 'Journey'),\n              size: 34,")
s=s.replace("              icon: Icons.extension_rounded,", "              height: 52,\n              icon: Icons.extension_rounded,")
a=s.index('class CollectionScreen')
part=s[a:]
part=part.replace('child: ListView(', 'child: Padding(\n        padding: const EdgeInsets.all(12),\n        child: Column(',1)
part=part.replace('        padding: const EdgeInsets.all(20),\n','')
part=part.replace('size: 46','size: 32').replace('height: 20','height: 10')
part=part.replace('          GridView.builder(', '          Expanded(child: GridView.builder(')
part=part.replace('            shrinkWrap: true,\n            physics: const NeverScrollableScrollPhysics(),\n','')
part=part.replace('          ),\n          const FooterNote(),','          )),')
part=part.replace('        ],\n      ),\n    );','        ],\n      )),\n    );')
s=s[:a]+part;p.write_text(s,encoding='utf-8')
# Visibility regression test for every bounded menu.
p=Path('test/widget_test.dart');s=p.read_text(encoding='utf-8')
pos=s.index("  testWidgets('daily reward") if "  testWidgets('daily reward" in s else s.index('  testWidgets(\n    \'daily reward')
s=s[:pos]+'''  testWidgets('all main menus fit on a 320 by 568 phone', (tester) async {
    final c = await launch(tester, size: const Size(320,568));
    for (final path in ['/', '/settings', '/reward', '/shop']) {
      c.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason:path);
      final scrollables = tester.stateList<ScrollableState>(find.byType(Scrollable));
      for (final scroll in scrollables) {
        expect(scroll.position.maxScrollExtent, lessThanOrEqualTo(1), reason:path);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

'''+s[pos:]
p.write_text(s,encoding='utf-8')
