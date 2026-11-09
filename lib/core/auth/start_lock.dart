/// Whether the app-wide biometric lock applies at process start.
enum StartLock {
  unlocked,
  locked,

  /// The setting could not be read (timeout or error). Treated as locked: the
  /// lock screen re-reads the setting and releases itself only if it is off.
  unknown;

  bool get startsLocked => this != StartLock.unlocked;
}

/// Reads the biometric-lock setting for the first frame. Fails closed: a slow
/// or broken keystore yields [StartLock.unknown], never [StartLock.unlocked].
Future<StartLock> resolveStartLock(
  Future<bool> Function() readSetting, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final enabled = await readSetting().timeout(timeout);
    return enabled ? StartLock.locked : StartLock.unlocked;
  } catch (_) {
    return StartLock.unknown;
  }
}
