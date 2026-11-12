# Browser SSO login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** "Sign in with <provider>" on the login screen, using the Paperless-ngx headless app login and AppAuth.

**Architecture:** `AuthService` discovers OIDC providers from Paperless, reads the scope, runs AppAuth through an injected function, swaps the `id_token` for a Paperless API token, then reuses `loginWithToken`. The auth notifier and login screen call it like the other two login methods.

**Tech Stack:** Flutter 3.41.3, Riverpod, Dio, `flutter_appauth` 12.1.0.

**Spec:** `docs/superpowers/specs/2026-11-08-oidc-login-design.md`

## Global Constraints

- `flutter_appauth: 12.1.0`, no Flutter or AGP change.
- Redirect URL `com.ventouxlabs.paperlessgo:/oidc-callback`.
- Paperless paths under `api/auth/headless/`.
- Fallback scopes `openid profile email`.
- Never log a token, `id_token` or code.
- `on DioException catch`, never bare `catch (e)` in new code.

## Review Focus

1. A server below 3.0 (404 on config) shows no SSO button and no error.
2. A provider entry without `client_id` or `openid_configuration_url` is skipped.
3. A redirect `Location` without `scope` falls back to the fixed scopes.
4. The exchange always sends the Paperless `client_id`, even with an app client ID set.
5. User cancelling the browser leaves the login screen without an error message.

---

### Task 1: SSO in AuthService

**Files:**
- Modify: `lib/core/auth/auth_service.dart`, `pubspec.yaml`, `pubspec.lock`, `pubspec.lock.fdroid`
- Test: `test/unit/auth/auth_service_sso_test.dart`

**Interfaces:**
- Produces: `class SsoProvider {id, name, clientId, openidConfigurationUrl}`;
  `typedef SsoAuthorize = Future<String?> Function({required String clientId, required String discoveryUrl, required List<String> scopes})` returning the `id_token`;
  `AuthService.fetchSsoProviders(String serverUrl) -> Future<List<SsoProvider>>`;
  `AuthService.loginWithSso(String serverUrl, SsoProvider provider, {String? appClientId}) -> Future<String?>` returning the API token, or null when the user cancelled;
  `AuthException` for every failure with the spec's messages.

- [ ] Tests: provider filtering, 404 gives empty list, scope from `Location`, scope fallback, exchange body, app client ID changes AppAuth client ID and adds the audience scope, MFA 401, other 401/403/409, 400, cancel returns null.
- [ ] Implement, run `flutter test test/unit/auth/`.

### Task 2: Notifier, screen and Android

**Files:**
- Modify: `lib/core/auth/auth_provider.dart`, `lib/features/login/login_screen.dart`, `android/app/build.gradle.kts`, `README.md`

**Interfaces:**
- Consumes: Task 1.
- Produces: `AuthState.loginWithSso(String serverUrl, SsoProvider provider, {String? appClientId})`.

- [ ] Notifier method mirrors `loginWithToken`; cancel returns to unauthenticated without throwing.
- [ ] Login screen loads providers after a successful connection test and shows one outlined button per provider plus the collapsed "Advanced" field.
- [ ] `manifestPlaceholders["appAuthRedirectScheme"] = "com.ventouxlabs.paperlessgo"` in `defaultConfig`.
- [ ] README SSO section: shared client (Authentik, Keycloak) and app client (Dex `trustedPeers`).
- [ ] `flutter analyze`, `flutter test`, `flutter build apk --debug`.
