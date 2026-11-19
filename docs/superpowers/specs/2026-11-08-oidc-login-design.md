# Design: Browser SSO login (OIDC)

**Date:** 2026-11-08
**Status:** Draft, awaiting approval
**Issue:** #51

## Intent

Users whose Paperless-ngx account comes from an SSO provider (Authentik,
Dex, Keycloak and others) have no local password. Today they must create
an API token in the web UI and paste it into the app. This adds a
"Sign in with <provider>" button that logs in through the provider in the
phone's browser and stores a normal Paperless API token.

## Goals

- G1. Works with any OpenID Connect provider configured in Paperless-ngx
  through `PAPERLESS_SOCIALACCOUNT_PROVIDERS` with `openid_connect`.
- G2. Uses the current OAuth rules for native apps: RFC 8252 and RFC 9700.
  Authorization code with PKCE S256, `state` and `nonce`, the system
  browser (Chrome Custom Tabs), no client secret in the app.
- G3. Username/password and API-token login stay unchanged.
- G4. The button appears only when the server offers a provider that
  supports this flow.

## Non-goals

- Paperless TOTP after SSO. The app shows a clear error instead (D1).
- Non-OIDC social providers (Google, GitHub and others as plain OAuth2).
- Upgrading Flutter or AGP.
- iOS. The app is Android only.
- Google configured directly as the Paperless provider. Google requires
  a client secret on web clients and Paperless rejects tokens issued to a
  different client ID. A broker in front of Google (Dex, Authentik,
  Keycloak), as in #51, works.

## Server requirements

Paperless-ngx 3.0.0 or newer. PR #11756 (allauth headless endpoints and
`DrfTokenStrategy`) is in v3.0.0 and not in v2.20.5, checked with the
GitHub compare API.

Paperless accepts an `id_token` only when its `aud` claim contains the
client ID Paperless is configured with (allauth
`OpenIDConnectProvider.verify_token`, PyJWT audience check). It does not
check `azp`. The app never holds a client secret, so the identity
provider needs a public client and must list
`com.ventouxlabs.paperlessgo:/oidc-callback` as a redirect URI. Two
setups satisfy this, checked against each provider's source on
2026-11-08:

- Shared client (Authentik, Keycloak). Switch the Paperless client to
  public and add the app redirect URI. Authentik (`token/base.py`) and
  Keycloak (`ClientIdAndSecretAuthenticator`) skip the secret check for
  public clients, so the Paperless web login keeps working while
  Paperless still sends its secret.
- App client (Dex). Dex (`grants/clientauth.go`) always compares the
  secret, so the shared setup would break the web login. Instead the
  admin adds a public Dex client for the app with the app redirect URI,
  and lists it in the Paperless client's `trustedPeers`. The app requests
  scope `audience:server:client_id:<paperless client id>`. Dex then
  issues `aud = [paperless, app]` and `azp = app`
  (`tokens/claims.go`, `tokens/crossclient.go`). The Paperless client
  stays confidential (Q4).

AppAuth-Android 0.11.1 accepts the token when `aud` contains its client
ID or `azp` equals it (`IdToken.validate`), so both setups pass its
checks. The README documents both setups.

## Approaches

- O1, chosen. Paperless headless app login with `flutter_appauth`.
  AppAuth (OpenID Foundation) runs the browser login, PKCE, `state`,
  `nonce` and the token request. The app keeps very little login security
  code of its own. No Google services, so the F-Droid build stays clean.
- O2, rejected. Same flow with `flutter_web_auth_2` and our own PKCE and
  token-request code. One dependency fewer, but the security-sensitive
  code becomes ours.
- O3, rejected. Load the Paperless web login in an in-app web page and
  read the session cookie. Google blocks sign-in inside in-app web pages,
  so it fails G1 for Google-backed setups such as the one in #51.

## Library

`flutter_appauth` 12.1.0. On Android it uses AppAuth-Android 0.11.1, the
newest release on Maven Central. As of 2026-11-08, OSV and the GitHub
Advisory Database list no vulnerabilities for either package, and none of
the upstream repos has a security advisory.

13.0.0 needs Flutter 3.44 and AGP 9; the app builds with Flutter 3.41.3
and AGP 8.9.1. Its changelog lists only the toolchain bump and iOS fixes,
so on Android it runs the same code. The upgrade is left to the
maintainer (Q3).

## Flow

All Paperless paths are under `/api/auth/headless/`.

1. Discover. `GET app/v1/config`. Keep providers whose `flows` contain
   `provider_token` and that have `client_id` and
   `openid_configuration_url`. A 404 or any other shape means the server
   has no SSO support; show no button.
2. Scope (D2). Get a CSRF cookie with `GET /accounts/login/`. Then
   `POST browser/v1/auth/provider/redirect` as a form with `provider`,
   `callback_url` (the server URL), `process=login` and the CSRF token in
   the body and the `X-CSRFToken` header, plus a `Referer`, without
   following redirects. Read `scope` from the `Location` header. If that
   fails, fall back to `openid profile email`.
3. Browser login. `FlutterAppAuth.authorizeAndExchangeCode` with
   `discoveryUrl` = `openid_configuration_url`, the scopes from step 2
   and redirect URL `com.ventouxlabs.paperlessgo:/oidc-callback`. The
   client ID is the provider's `client_id`, or the optional app client
   ID when the user filled it in. With an app client ID, the scopes also
   get `audience:server:client_id:<provider client_id>`. AppAuth checks `state`,
   `nonce` and the token response. Only the `idToken` is used; the
   provider's access and refresh tokens are dropped.
4. Exchange. `POST app/v1/auth/provider/token` as JSON:
   `{"provider": <id>, "process": "login", "token": {"client_id":
   <provider client_id>, "id_token": <idToken>}}`. Always the client ID
   Paperless advertised, because allauth looks up its app by it. On 200, the API token is `meta.access_token`.
5. Store. Save the server URL and token the way `loginWithToken` does.
   The token came straight from Paperless, so it skips the extra
   `api/statistics/` check.

## Errors

- User closes the browser: no message, stay on the login screen.
- 401 with a pending `mfa_authenticate` flow: "This account uses
  two-factor login, which SSO in the app does not support yet. Use an API
  token instead." (D1)
- 409 or 403 from step 4 (signup closed or pending signup): "Paperless
  did not allow this account to sign in. Ask your Paperless admin."
- 400 from step 4 (`invalid_token`, usually an audience mismatch): "The
  identity provider client does not match Paperless. Check the SSO setup
  in the README."
- AppAuth errors (redirect URI not allowed, client secret required):
  "The identity provider rejected the app. Check the SSO setup in the
  README."
- Network errors use the existing `_describeConnectionError`.

No token, `id_token` or code is ever logged.

## Code changes

- `pubspec.yaml`, `pubspec.lock`, `pubspec.lock.fdroid`: add
  `flutter_appauth: 12.1.0`.
- `android/app/build.gradle.kts`: `manifestPlaceholders["appAuthRedirectScheme"] = "com.ventouxlabs.paperlessgo"`.
  AppAuth's own redirect activity receives the callback, so it never
  reaches GoRouter.
- `lib/core/auth/auth_service.dart`: `fetchSsoProviders(serverUrl)` and
  `loginWithSso(serverUrl, provider)`. The AppAuth call goes through an
  injected function so tests can fake it, like `_dioFactory`.
- `lib/core/auth/auth_provider.dart`: `loginWithSso` on the auth notifier,
  matching `loginWithToken`.
- `lib/features/login/login_screen.dart`: after a successful connection
  test, load providers and show one outlined "Sign in with <name>" button
  per provider under the Login button. Under the buttons, a collapsed
  "Advanced" section holds the optional "App client ID" field with the
  helper text "Only for Dex cross-client setups. Leave empty otherwise."
  It is not saved; a later login asks again.
- Tests in `test/unit/auth/`: provider filtering, scope parsing and
  fallback, the app client ID changing the AppAuth client ID and scopes
  but not the exchange `client_id`, token exchange success, and each
  error mapping above, using a fake Dio adapter and a fake AppAuth
  function.
- `README.md`: SSO setup section with the shared-client and app-client
  setups, including a Dex `staticClients` example.

## Decisions

- Q3. `flutter_appauth` 12.1.0, no toolchain change.
- D1. Paperless TOTP after SSO shows an error.
- D2. Scopes come from Paperless, with a fixed fallback.
- Q4. Dex works through an optional app client ID and Dex cross-client
  trust, keeping the Paperless client confidential.
- D8. The login screen tests the connection by itself 800 ms after the
  URL stops changing, or on Enter, once the URL has a host. The owner could not find the test
  icon, so the SSO button never appeared.
- D9. `MainActivity` drops `android:taskAffinity=""`. With it, AppAuth's
  callback opened a new `AuthorizationManagementActivity` without the
  login state ("No stored state - unable to handle response"), as the
  flutter_appauth README warns. `launchMode="singleTask"` stays for share
  intents. The empty affinity came from the Flutter template as a guard
  against task hijacking (StrandHogg). Dropping it gives up that guard;
  I have not confirmed whether current Android versions block that attack
  on their own.

## Verification

- Unit tests as listed above.
- `flutter analyze` and `flutter test` in a Flutter 3.41.3 container.
- Manual end to end on an Android 14 emulator against a self-hosted
  Paperless-ngx 3.4.2 with Authentik 2026.8.5: the URL check, the
  "Sign in with Authentik" button, login in a Custom Tab, return to the
  app and the document library loading.

## Left to the builder

- Debug and release builds share the redirect scheme. With both installed
  Android shows a chooser. Acceptable for a debug build.
- Exact widget layout, following existing login screen tokens.
