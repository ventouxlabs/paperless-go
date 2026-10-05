# Native chat live verification

Verified against the existing localhost-only Paperless-ngx 3.2.1 test instance
at `http://127.0.0.1:8020`, using its three fictional documents. No production
or reviewer-demo documents were used.

The first request returned HTTP 200 with `text/event-stream` and the documented
generation-failed sentence. Server logs identified the missing embedding
backend (`Unsupported embedding backend: None`).

To verify success, the test temporarily supplied an OpenAI-compatible embedding
stub inside the test container, rebuilt the three-document index, and preserved
the existing OmniRoute language-model route. The stub provided deterministic
vectors; this verifies the chat protocol and client integration, not semantic
retrieval quality of an actual embedding model.

The live tests used the production `DioClient`, `PaperlessApi.openNativeChat`,
and `NativeChatService` rather than a fake transport. All three passed:

- Document chat returned a nonempty answer and the requested document reference;
  the metadata delimiter was absent from displayed answer text.
- Archive chat returned a nonempty answer and parsed document references.
- A nonexistent document returned HTTP 400 as a `DioException`.

The temporary embedding configuration was restored to its original values in
`finally`. The test server's language-model configuration and documents were
not changed. Successful requests took approximately seven and two seconds.

## Repeating the client verification

`test/live/native_chat_live_test.dart` is opt-in and skipped in ordinary test
runs. Configure a fictional-document test server with a working language model
and embedding index, then supply these process environment variables:

- `PAPERLESS_CHAT_TEST_URL`: base URL including trailing slash.
- `PAPERLESS_CHAT_TEST_TOKEN`: API token, supplied securely without committing it.
- `PAPERLESS_CHAT_TEST_DOCUMENT_ID`: ID of a document in the test index.

Run `flutter test --no-pub test/live/native_chat_live_test.dart -r expanded`.
This sends two questions to the configured language model. HTTP logging is
disabled for these tests to keep credentials and session headers out of output.

This was endpoint/client verification. On-device UI testing, embedding relevance,
and proxy buffering behavior remain separate checks.
