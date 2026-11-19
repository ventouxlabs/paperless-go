/// Gate for actions that send a document's file off the device (share,
/// save to folder) from places that never passed the per-document lock,
/// such as the Library's long-press menu and bulk selection.
///
/// A locked document needs the same biometric check as opening it, and its
/// exported file is named after its id, never its real title.
library;

/// The outcome of [clearForExport]: whether the export may go ahead, and
/// which documents are locked (so their names can be masked).
class ExportClearance {
  final bool allowed;
  final Set<int> lockedIds;

  ExportClearance._({required this.allowed, required Set<int> lockedIds})
      : lockedIds = Set.unmodifiable(lockedIds);

  /// The title to name an exported file after: the real [title] for an
  /// unlocked document, `document_<id>` for a locked one.
  String exportTitleFor(int id, String title) =>
      lockedIds.contains(id) ? lockedExportName(id) : title;
}

/// The name used in place of a locked document's title.
String lockedExportName(int id) => 'document_$id';

/// Decides whether [documentIds] may be exported.
///
/// Prompts [authenticate] once if any of them is locked. Fails closed: if
/// the lock set cannot be read, every document is treated as locked, and an
/// authentication that throws counts as a refusal.
Future<ExportClearance> clearForExport({
  required Iterable<int> documentIds,
  required Future<Set<int>> Function() loadLockedIds,
  required Future<bool> Function() authenticate,
}) async {
  final ids = documentIds.toSet();
  final Set<int> locked;
  try {
    locked = (await loadLockedIds()).intersection(ids);
  } on Exception {
    return _authenticated(ids, authenticate);
  }
  if (locked.isEmpty) {
    return ExportClearance._(allowed: true, lockedIds: const {});
  }
  return _authenticated(locked, authenticate);
}

Future<ExportClearance> _authenticated(
  Set<int> locked,
  Future<bool> Function() authenticate,
) async {
  bool ok;
  try {
    ok = await authenticate();
  } on Exception {
    ok = false;
  }
  return ExportClearance._(allowed: ok, lockedIds: locked);
}
