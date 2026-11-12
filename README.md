# 小竹 · Little Bamboo

A native iOS parenting companion for Chinese families. A calm space to ask about big feelings, bilingual upbringing, grandparents’ involvement, daily routines, and parents’ wellbeing, in Chinese or English.

Built with SwiftUI (iOS 18+) and a small authenticated Node/Vercel service using Claude. No third-party iOS dependencies or server npm dependencies.

## What works

- Chinese and English interfaces and automatic or selected reply language.
- Real AI conversations with recent conversation context and optional family context.
- Topic starters, local conversation history, retry after failed replies.
- Saved advice, native sharing, optional child nickname/age/context.
- App access key stored in iOS Keychain; provider key held only on the server.
- Delete local chats, bookmarks, and family details in Family settings.

The hosted page is a project introduction, not a browser version of the app. This is a private prototype, not an App Store release. There are no accounts or cross-device sync.

## Run the iOS app

Requires macOS, Xcode 16+ with an iOS 18+ SDK, and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate --spec ios/project.yml
open ios/LittleBamboo.xcodeproj
```

Choose the LittleBamboo scheme and an iPhone simulator, then Run. The generated project is checked in for convenience; regenerate after changing the project specification.

Open **Family → AI connection**, enter the HTTPS origin of your service and its private **app access key**, then Save. This is the server's `CHAT_ACCESS_KEY`, not an Anthropic API key. The default origin is `https://little-bamboo.vercel.app`. The app is fully browsable without a key and explains how to connect when a message cannot be sent. Failed questions can be retried after setup.

For a physical iPhone, select an Apple development team in Xcode's Signing & Capabilities and use a unique bundle identifier if necessary. TestFlight/App Store distribution needs your Apple Developer account, signing, and App Store Connect setup.

## Deploy the AI service

Deploy `server/` as a Vercel project named `little-bamboo`, with Node.js 22. Configure these server environment variables securely in Vercel:

| Variable | Purpose |
| --- | --- |
| `ANTHROPIC_API_KEY` | Provider key, never placed in the iOS project |
| `CHAT_ACCESS_KEY` | Random app access key of at least 32 characters |
| `ANTHROPIC_MODEL` | Optional; defaults to `claude-haiku-4-5` |

```sh
npx vercel server --prod
```

`POST /api/chat` requires `Authorization: Bearer <CHAT_ACCESS_KEY>` and JSON with `messages` (alternating user/assistant turns, ending in user) and optional `profile` (`nickname`, `ageMonths`, `context`, `language`: `auto`, `en`, or `zh`). Requests are limited to 20 messages, 4,000 characters per message, 24,000 total characters, and 48 KB. Recent context sent by the app is bounded to 20 turns. Responses are `{ "reply": "…" }` or `{ "error": "…" }`.

`GET /api/health` reports process health without exposing configuration or credentials.

For local server work, inject keys through your shell or secret manager and run `npm run dev` in `server/`. Do not commit credentials. The native app requires HTTPS, so use an HTTPS development tunnel if pointing it at a local service.

## Privacy and limitations

Conversation history, saved replies, and optional family details are stored in the app's Application Support directory with iOS file protection. These files are not synced by the app; OS-managed device backups may include them. The app access key is stored in a device-only Keychain item. Deleting family data leaves connection settings intact; clear the access-key field separately to disconnect.

Sending a message transmits recent chat history and optional family context through the Vercel service to Anthropic. The service does not persist or log message contents. Vercel and Anthropic may retain operational/request data under their policies. Avoid entering identifying or sensitive information unnecessarily. This prototype has no analytics SDK.

The assistant offers general parenting support, not medical care. Its instructions discourage punishment and shame, avoid diagnosis/prescribing, ask for age when relevant, and prioritize urgent professional help for safety concerns. Model behavior is probabilistic; these instructions are not a clinical safety guarantee.

The shared access key is suitable for a trusted personal prototype. The service includes bounded input/output, a provider timeout, and best-effort per-instance throttling (12 calls/minute, 3 concurrent). The throttle is not a durable, distributed spending cap. Before a public launch, add individual authentication, durable per-user quotas, abuse controls, a provider budget, and a production privacy/support policy.

## Verification

```sh
npm --prefix server test
xcodegen generate --spec ios/project.yml
xcodebuild -project ios/LittleBamboo.xcodeproj -scheme LittleBamboo \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

If that simulator is unavailable, use an available iPhone UDID from `xcrun simctl list devices available` instead. Unit tests cover multilingual persistence, bookmark lifecycle, failed-request retry without duplicate messages, corrupt-data preservation, and local deletion. Service tests cover authentication, request validation, language/context forwarding, error redaction, incomplete answers, and local throttling. GitHub Actions runs both suites without provider credentials. There are no pre-commit hooks.
