# Native AI fixtures (Paperless-ngx 3.2.1)

Captured 2026-10-04 from a throwaway Paperless-ngx 3.2.1 server with the
native AI module on (`openai-like` backend, `gemini-3.5-flash-lite`). All
documents are fictional. Users are sanitized.

| File | Status | Content-Type |
|---|---|---|
| `ai_suggestions_bill.json` | 200 | application/json |
| `ai_suggestions_new_correspondent.json` | 200 | application/json (suggests a correspondent not in the DB) |
| `ai_suggestions_403.txt` | 403 | text/html; charset=utf-8 (plain text, not JSON) |
| `ai_suggestions_404.json` | 404 | application/json |
| `ai_suggestions_502_backend_rejected.json` | 502 | application/json (provider rejected forced tool_choice) |
| `document_detail_admin.json` | 200 | `user_can_change: true` |
| `document_detail_viewer.json` | 200 | `user_can_change: false` (view-only user) |
| `document_detail_editor_object_view_only.json` | 200 | `user_can_change: false` (global change_document, object-level view only) |
| `ui_settings_ai_enabled.json` | 200 | `settings.ai_enabled: true` |
| `ui_settings_viewer.json` | 200 | AI on, no `change_document` |
| `ui_settings_viewer_403_no_uisettings_perm.json` | 403 | user lacks `view_uisettings` |

Object IDs on that server: tags Invoice=1, Utilities=2, Insurance=3, Tax=4;
correspondents Acme Energy=1, Northwind Insurance=2; types Bill=1, Letter=2.
