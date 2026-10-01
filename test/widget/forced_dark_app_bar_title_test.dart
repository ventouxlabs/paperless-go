// The PDF viewer and the crop screen force a black AppBar. The app theme's
// AppBar titleTextStyle carries the ink colour, and a theme title style wins
// over the AppBar's foregroundColor, so the title rendered ink-on-black and
// was nearly unreadable. The title must be white like the icons.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/documents/document_preview_screen.dart';
import 'package:paperless_go/features/scanner/crop_screen.dart';

Color? _titleColor(WidgetTester tester, String title) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    )
    .text
    .style
    ?.color;

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('document preview title is white in the $name theme',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paperlessApiProvider.overrideWith((ref) => PaperlessApi(Dio())),
          ],
          child: MaterialApp(
            theme: theme,
            home: const DocumentPreviewScreen(documentId: 1),
          ),
        ),
      );

      expect(_titleColor(tester, 'Loading...'), Colors.white);
    });

    testWidgets('crop title is white in the $name theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const CropScreen(imagePath: '/nonexistent.jpg'),
        ),
      );

      expect(_titleColor(tester, 'Crop'), Colors.white);
    });
  }
}
