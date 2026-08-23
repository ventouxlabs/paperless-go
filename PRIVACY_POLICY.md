> ⚠️ **Superseded.** The canonical privacy policy is
> [`play-store/privacy-policy.md`](play-store/privacy-policy.md), published at
> <https://ventouxlabs.github.io/paperless-go/privacy-policy.html>. Use that URL on
> the Play listing. This file is kept for reference only.

# Privacy Policy for Paperless Go

**Last updated:** April 25, 2026

## Overview

Paperless Go is an open-source mobile client for Paperless-ngx, a self-hosted document management system. This app does not collect, store, or transmit any user data to the developer or any third party. All data remains between your device and your own Paperless-ngx server.

## Data Collection

**We do not collect any data.** Paperless Go:

- Does not use analytics or tracking services
- Does not contain advertisements
- Does not collect crash reports
- Does not use any third-party data collection SDKs
- Does not store any data on external servers

## Data Flow

All network communication occurs exclusively between your device and the Paperless-ngx server that you configure. This includes:

- **Documents and metadata** — fetched from and sent to your server
- **Authentication tokens** — stored locally on your device using encrypted storage and sent to your server for authentication
- **Thumbnails and previews** — downloaded from your server and cached locally on your device

No data is routed through any intermediary servers operated by the developer.

## Data Storage on Your Device

Paperless Go stores the following data locally on your device:

- **Server URL and authentication token** — stored in encrypted secure storage
- **Cached document thumbnails** — stored in the app's cache directory
- **Offline database** — a local copy of document metadata for offline browsing

All local data is removed when you uninstall the app or clear the app's data through your device settings.

## Permissions

Paperless Go requests the following device permissions:

| Permission | Purpose |
|---|---|
| **Internet** | Communicate with your Paperless-ngx server |
| **Camera** | Scan documents using your device's camera |
| **Biometric/Fingerprint** | Optional biometric lock for the app |
| **Notifications** | Show upload progress and completion status |
| **Read/Write Storage** | Access files for document upload |

All permissions are used solely for the stated purposes and no data from these permissions is transmitted to any third party.

## Third-Party Services

The only external connection is to the Paperless-ngx server that you configure and control.

**Google ML Kit (Play Store builds only):** Builds distributed via Google Play include Google ML Kit for on-device text recognition, used to suggest document metadata during scanning. ML Kit runs entirely on your device — no images or text are sent to Google's servers. Builds distributed via F-Droid do not include ML Kit and use a pure-Dart fallback instead.

## Children's Privacy

Paperless Go does not knowingly collect any data from children or any other users. The app does not collect data from anyone.

## Changes to This Policy

If this privacy policy is updated, the changes will be posted in the app's source code repository at https://github.com/ventouxlabs/paperless-go.

## Contact

If you have questions about this privacy policy, please open an issue at:
https://github.com/ventouxlabs/paperless-go/issues

## Open Source

Paperless Go is free and open source software licensed under the GNU Affero General Public License v3.0. You can review the complete source code at https://github.com/ventouxlabs/paperless-go.
