from pathlib import Path
p=Path('test/widget_test.dart');s=p.read_text(encoding='utf-8');s=s.replace("    await tester.scrollUntilVisible(find.text('Sonraki'), 100);", "    expect(find.text('Sonraki').hitTestable(), findsOneWidget);\n    expect(find.byType(Scrollable), findsNothing);");p.write_text(s,encoding='utf-8')
p=Path('lib/core/services/feedback_service.dart');s=p.read_text(encoding='utf-8').replace('inMilliseconds < 1100)\n      return;', 'inMilliseconds < 1100) {\n      return;\n    }');p.write_text(s,encoding='utf-8')
p=Path('lib/features/gameplay/application/game_session.dart');s=p.read_text(encoding='utf-8').replace('      return shapes[_random.nextInt(shapes.length)];', '''      final index = _random.nextInt(shapes.length);
      if (mode != GameMode.classic) {
        for (var offset = 0; offset < shapes.length; offset++) {
          final candidate = shapes[(index + offset) % shapes.length];
          if (service.firstMove(board, candidate) != null) return candidate;
        }
      }
      return shapes[index];''');p.write_text(s,encoding='utf-8')
