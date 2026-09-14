# Speak distribution options

Checked 2026-09-13 against Apple's published documentation. This is planning research, not a submission or a promise of approval.

## Current constraint

Speak currently reads and replaces selected text in other applications using Accessibility APIs (`app/Sources/SpeakApp/Insertion.swift`). Apple requires App Sandbox for Mac App Store distribution and lists use of accessibility APIs in assistive apps among incompatible functionality. The current unsandboxed, ad-hoc signed development build cannot simply be uploaded as-is. See [Apple's sandbox guidance](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox) and [App Review Guidelines, 2.4.5](https://developer.apple.com/app-store/review/guidelines/).

Engineering conclusion: resolve the insertion architecture and sandbox compatibility before investing in a full Mac App Store submission. TTS and dictation inside Speak with manual copy are a possible narrower store edition; compatibility and review acceptance still need validation. The model cache, downloads, microphone access, and Raycast socket/CLI integration also need a sandbox design review. Do not assume an external helper or temporary entitlement resolves the store requirements.

## Mac App Store process

1. Enroll in the Apple Developer Program as an individual or organization. Membership is currently USD 99 per year, with regional pricing. [Enrollment](https://developer.apple.com/programs/enroll/).
2. Build and test a sandbox-compatible release, configure signing and entitlements, package model setup, and complete source/model license notices. Replace the development-only build/controller paths with an installation flow. [Distribution preparation](https://help.apple.com/xcode/mac/current/en.lproj/dev91fe7130a.html).
3. Create the App Store Connect listing and upload a signed build. Supply screenshots, description, privacy disclosures, privacy policy, support URL, and review instructions explaining local models and permissions. [Submission overview](https://developer.apple.com/app-store/submitting/) and [review information](https://developer.apple.com/app-store/review/).
4. Submit the chosen build and metadata to App Review, address any findings, and release after approval. [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app).

No enrollment, payment, agreement acceptance, or submission has been performed.

## Recommended first public release

For the full shortcut-to-any-app experience, first prepare a directly distributed Mac app signed with Developer ID, hardened, notarized, and delivered in a downloadable installer or DMG. Apple supports this distribution route; notarization checks malware/signing and is separate from App Store review. This recommendation follows from our current Accessibility-based implementation, and does not change the chosen product scope. [Apple's Developer ID and notarization overview](https://developer.apple.com/developer-id/).

The Raycast extension has a separate distribution/review path through Raycast's extension store. It is currently installed only in local development mode. Mac App Store publication would not publish the Raycast extension automatically.
