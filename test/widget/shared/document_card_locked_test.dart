import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/models/tag.dart';
import 'package:paperless_go/shared/widgets/document_card.dart';

Widget _card({required bool locked}) => MaterialApp(
      home: Scaffold(
        body: DocumentCard(
          document: const Document(id: 1, title: 'Secret', tags: [7]),
          tags: const {7: Tag(id: 7, name: 'Medical', slug: 'medical')},
          correspondents: const {},
          documentTypes: const {},
          thumbnailUrl: 'https://example.invalid/api/documents/1/thumb/',
          authToken: 'Token x',
          locked: locked,
        ),
      ),
    );

void main() {
  group('DocumentCard locked', () {
    testWidgets('does not render the thumbnail for a locked document',
        (tester) async {
      await tester.pumpWidget(_card(locked: true));
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders the thumbnail for an unlocked document',
        (tester) async {
      await tester.pumpWidget(_card(locked: false));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });
 
    testWidgets('masks title and tags for a locked document', (tester) async {
      await tester.pumpWidget(_card(locked: true));
      expect(find.text('Secret'), findsNothing);
      expect(find.text('Medical'), findsNothing);
      expect(find.text(lockedDocumentTitle), findsOneWidget);
    });

    testWidgets('shows title and tags for an unlocked document',
        (tester) async {
      await tester.pumpWidget(_card(locked: false));
      expect(find.text('Secret'), findsOneWidget);
      expect(find.text('Medical'), findsOneWidget);
    });
  });
}
