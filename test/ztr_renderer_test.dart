import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ff13_mod_resource/src/utils/ztr_text_renderer.dart';
import 'package:ff13_mod_resource/models/app_game_code.dart';

void main() {
  testWidgets('ZtrTextRenderer renders singular only by default', (WidgetTester tester) async {
    const text = 'Creature Comforts{End}{StraightLine}Creature Comforts{End}{Article}an e-pass for{End}{ArticleMany}e-passes for';
    
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ZtrTextRenderer.render(text, AppGameCode.ff13_1, displayMultiple: false),
      ),
    );

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsOneWidget);

    final RichText richText = tester.widget(richTextFinder);
    final String plainText = richText.text.toPlainText();

    expect(plainText, 'An e-pass for Creature Comforts');
    expect(plainText, isNot(contains('SINGLE:')));
    expect(plainText, isNot(contains('MULTIPLE:')));
  });

  testWidgets('ZtrTextRenderer renders both when displayMultiple is true', (WidgetTester tester) async {
    const text = 'Creature Comforts{End}{StraightLine}Creature Comforts{End}{Article}an e-pass for{End}{ArticleMany}e-passes for';
    
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ZtrTextRenderer.render(text, AppGameCode.ff13_1, displayMultiple: true),
      ),
    );

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsOneWidget);

    final RichText richText = tester.widget(richTextFinder);
    final String plainText = richText.text.toPlainText();

    expect(plainText, contains('SINGLE: An e-pass for Creature Comforts'));
    expect(plainText, contains('MULTIPLE: E-passes for Creature Comforts'));
  });

  testWidgets('ZtrTextRenderer handles missing ArticleMany', (WidgetTester tester) async {
    const text = 'Creature Comforts{End}{StraightLine}Creature Comforts{End}{Article}an e-pass for';
    
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ZtrTextRenderer.render(text, AppGameCode.ff13_1, displayMultiple: true),
      ),
    );

    final richTextFinder = find.byType(RichText);
    final RichText richText = tester.widget(richTextFinder);
    final String plainText = richText.text.toPlainText();

    expect(plainText, contains('SINGLE: An e-pass for Creature Comforts'));
    // Fallback to just plural base if prefixMany is missing (based on my implementation)
    expect(plainText, contains('MULTIPLE: Creature Comforts'));
  });
  
  test('stripTags correctly formats output with ArticleMany', () {
      const text = 'Creature Comforts{End}{StraightLine}Creature Comforts{End}{Article}an e-pass for{End}{ArticleMany}e-passes for';
      final stripped = ZtrTextRenderer.stripTags(text);
      expect(stripped, contains('SINGLE: An e-pass for Creature Comforts'));
      expect(stripped, contains('MULTIPLE: E-passes for Creature Comforts'));
  });
}
