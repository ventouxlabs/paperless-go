import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/scanner/scanner_screen.dart';

void main() {
  group('isReviewableImagePath', () {
    for (final extension in ['png', 'jpg', 'jpeg', 'tiff', 'webp']) {
      test('recognizes .$extension image paths', () {
        expect(isReviewableImagePath('/pictures/scan.$extension'), isTrue);
      });
    }

    test('is case insensitive', () {
      expect(isReviewableImagePath('/pictures/scan.JPG'), isTrue);
    });

    test('does not treat PDFs or extensionless paths as images', () {
      expect(isReviewableImagePath('/documents/scan.pdf'), isFalse);
      expect(isReviewableImagePath('/documents/scan'), isFalse);
    });
  });
}
