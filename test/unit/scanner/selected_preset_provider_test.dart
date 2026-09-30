// #42: the enhancement preset picked on the scanner hub is remembered across
// scanner sessions and app restarts — including "None" — instead of
// resetting to Auto every time.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/constants.dart';
import 'package:paperless_go/features/scanner/processing/presets.dart';
import 'package:paperless_go/features/scanner/providers/selected_preset_provider.dart';

/// Storage whose writes fail, as the Android keystore sometimes does.
class _FailingWrites extends SecureStorageService {
  _FailingWrites() : super(storage: const FlutterSecureStorage());

  @override
  Future<void> saveScannerPreset(String name) async =>
      throw Exception('keystore unavailable');
}

/// A fresh container, as after an app restart. Listening builds the provider
/// right away, so the stored value starts loading immediately.
ProviderContainer _restart() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.listen(selectedPresetProvider, (_, __) {});
  return container;
}

/// Lets the async storage read complete.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('defaults to Auto when nothing was chosen yet', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = _restart();
    await _settle();

    expect(container.read(selectedPresetProvider), ProcessingPreset.auto);
  });

  test('a choice of None survives a restart', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = _restart();
    await first.read(selectedPresetProvider.notifier).select(ProcessingPreset.none);
    expect(first.read(selectedPresetProvider), ProcessingPreset.none);

    final second = _restart();
    await _settle();

    expect(second.read(selectedPresetProvider), ProcessingPreset.none);
  });

  test('an unknown stored value falls back to Auto', () async {
    FlutterSecureStorage.setMockInitialValues(
        {StorageKeys.scannerPreset: 'sepia'});
    final container = _restart();
    await _settle();

    expect(container.read(selectedPresetProvider), ProcessingPreset.auto);
  });

  test('a pick made before the stored value loads is not overwritten',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {StorageKeys.scannerPreset: ProcessingPreset.receipt.name});
    final container = _restart();
    // No settle: the user taps a chip before the storage read returns.
    await container.read(selectedPresetProvider.notifier).select(ProcessingPreset.photo);
    await _settle();

    expect(container.read(selectedPresetProvider), ProcessingPreset.photo);
  });

  test('a failed save leaves the previous preset shown and reports it',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWith((ref) => _FailingWrites())],
    );
    addTearDown(container.dispose);
    container.listen(selectedPresetProvider, (_, __) {});
    await _settle();

    await expectLater(
      container.read(selectedPresetProvider.notifier).select(ProcessingPreset.none),
      throwsException,
    );
    // The chip must not claim a choice that won't survive a restart.
    expect(container.read(selectedPresetProvider), ProcessingPreset.auto);
  });
}
