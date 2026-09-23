from pathlib import Path
p=Path('test/widget_test.dart');s=p.read_text(encoding='utf-8');s=s.replace("      final scrollables = tester.stateList<ScrollableState>(", """      if (path == '/reward') {
        final list = tester.widget<ListView>(find.byType(ListView).first);
        for (final child in (list.childrenDelegate as SliverChildListDelegate).children) {
          print('${child.runtimeType}: ${tester.getSize(find.byWidget(child))}');
        }
      }
      final scrollables = tester.stateList<ScrollableState>(""");p.write_text(s,encoding='utf-8')
