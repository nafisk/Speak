# Wispr Flow design audit and Speak alternative

Research date: 2026-09-13. The referenced product is **Wispr Flow**. This is a desktop-focused audit of its publicly documented experience and published visual assets, with mobile patterns included only for context. No installed Wispr Flow app was found in `/Applications`; no account, permissions, or live dictation session was used. This is not a claim that every production screen or animation was exercised.

## Evidence and confidence

| Evidence | What was checked | Limits |
| --- | --- | --- |
| [Official website](https://wisprflow.ai/) | Browser screenshot of current landing page | Marketing, not native app UI |
| [Official media kit](https://wisprflow.ai/media-kit) and its [Product UI archive](https://cdn.prod.website-files.com/682f84b3838c89f8ff7667db/6a748070c9b1aca19a08096b_Product%20UI%20-%20Final.zip) | Mac home, Dictionary, Snippets, both Styles screens, Insights, Notepad, Notetaker Hub | Static promotional images; version not stated |
| [Navigation guide](https://docs.wisprflow.ai/articles/5096240724-navigating-the-wispr-flow-app-desktop-ios-and-android) | Hub, bar, menus, settings, platform differences | Describes behavior, not measured appearance |
| [Setup guide](https://docs.wisprflow.ai/articles/3152211871-setup-guide) | Permissions, microphone test, shortcuts, guided practice | No firsthand onboarding test |
| [First dictation](https://docs.wisprflow.ai/articles/6409258247-starting-your-first-dictation), [hands-free](https://docs.wisprflow.ai/articles/6391241694-use-flow-hands-free), [formatting](https://docs.wisprflow.ai/articles/5373093536-how-do-i-use-smart-formatting-and-backtrack) | Start/stop, insertion, recovery, cleanup | Some documentation conflicts, listed below |
| [Podfeet review, March 2026](https://www.podfeet.com/blog/2026/03/wispr-flow-scott-willsey/) | Published Flow Bar and General Settings screenshots | Secondary, older evidence; not current-version authority |

Reference images are kept only in ignored `prototypes/output/flow-audit/` for inspection. The Speak concept contains original markup and text, with no Flow logo, photos, illustrations, or proprietary fonts.

## Visual language

**Observed in official app screenshots:** a warm shell surrounds a large near-white rounded content panel. Selected navigation uses a pale neutral fill. Primary buttons are dark rounded rectangles; secondary actions use warm neutral fills. Outline icons and sans-serif labels organize navigation. Serif headings appear in feature banners, style examples, and note titles. Promotional imagery is softly blurred and warm. Lists use subtle horizontal rules. Insights introduces teal graphics; style examples also contain lavender. [Product visuals](https://wisprflow.ai/media-kit).

The website is more expressive: pale cream background, large serif headline with italic emphasis, black lettering, lavender calls to action, and occasional deep green. That does not mean every app control uses the website palette. [Website](https://wisprflow.ai/).

### Sampled colors, not an official token specification

The following values occur prominently in the original PNG pixels. They describe the published images, not verified native semantic colors or accessibility guarantees.

| Role inferred from screenshots | Sample | Evidence |
| --- | --- | --- |
| Warm window/sidebar | `#F5F4F0` | Mac-home, Dictionary |
| Main content | `#FCFCFB` | Mac-home, Dictionary |
| Selected/secondary surface | `#EEEBE3` | Mac-home, Dictionary |
| Ink / primary control | `#1A1A1A` | Dictionary, Mac-home |
| Soft boundary | `#E0DDD5` | Dictionary |
| Lavender example surface | `#F8F6FE` | Styles2 |

Counts were computed from the unmodified PNGs using Pillow. Exact font families, point sizes, radii, spacing tokens, and animation curves were not published in the inspected assets. The supplied home image is 2276 × 1500 pixels; it is not evidence of the native window's logical point dimensions.

**Interpretation for Speak:** Flow feels like a calm writing workspace because of the warm paper/ink contrast and the separation between expressive headings and practical controls. Native glass is not the defining feature of these screenshots. A dense application can borrow that warmth without reproducing the large hub, promotional banners, or extensive navigation.

## Information architecture

The desktop experience separates the **Hub** from the **Flow Bar**. The guide documents history, dictionary, snippets, writing styles, and scratchpad in the Hub, with settings/help lower in navigation. The bar handles dictation and exposes microphone, history, and paste-last-text actions through a contextual menu. Settings separates computer behavior from account/privacy management. [Navigation guide](https://docs.wisprflow.ai/articles/5096240724-navigating-the-wispr-flow-app-desktop-ios-and-android).

The published images additionally show Insights, Notetaker, and differing labels such as Transforms/Polish and Scratchpad/Notes. These images should not be combined into an invented, definitive current sitemap. [Product visuals](https://wisprflow.ai/media-kit).

**Speak decision:** retain the architectural separation, but keep the optional main window focused on reading and settings. Dictation stays in the floating control. Dictionary, snippets, history dashboards, accounts, teams, and meeting notes are not added to the MVP by this exploration.

## Interaction audit

### Starting and ending dictation

Official instructions describe holding Fn to record on Mac and releasing to insert. Hands-free uses Fn + Space to toggle. Escape cancels. The moving white bars and optional sound establish that listening has begun. Flow targets the field active at the start; when insertion fails, a manual paste route preserves access to the result. [First dictation](https://docs.wisprflow.ai/articles/6409258247-starting-your-first-dictation).

A March screenshot shows a black idle lozenge, a separate black shortcut hint, and light text. Its accompanying review describes hover expansion and a larger recording indicator. [Flow Bar screenshot](https://www.podfeet.com/blog/wp-content/uploads/2026/03/Wispr-Record-Lozenge2.png), [review](https://www.podfeet.com/blog/2026/03/wispr-flow-scott-willsey/).

**Speak decision:** use the user's toggle shortcut as the default. A dark capsule with light waveform gives strong separation from arbitrary desktop content. Preserve focus, show real microphone energy, and distinguish preparing, listening, transcribing, success, and recovery. The illustrative trigger remains visible in the study so the user can discover the demo; production need not show an idle pill.

### Onboarding and permission recovery

Flow's setup documents browser sign-in, microphone/accessibility permissions, a live microphone test, shortcut selection, language selection, and practice dictations. It includes skip paths and action-oriented microphone errors. [Setup guide](https://docs.wisprflow.ai/articles/3152211871-setup-guide).

**Speak decision:** borrow the learn-by-doing sequence: explain local models, download with progress, grant needed permissions, verify microphone input, choose shortcut, complete one insertion. Keep TTS available where possible if dictation permissions are missing. Do not introduce account creation merely to match another product's setup.

### Formatting and correction

Flow documents automatic lists from sequence words, surrounding-text formatting, and removal of false starts/self-corrections. It also offers access to the original result through undoing AI cleanup. [Formatting guide](https://docs.wisprflow.ai/articles/5373093536-how-do-i-use-smart-formatting-and-backtrack).

**Speak decision:** visual similarity must not imply equivalent language understanding. Keep Plain and Spoken lists accurately labeled. Retain original wording and raw transcript. The present local prototype recognizes explicit list cues; broader cleanup needs separate feasibility and acceptance work.

### Settings, errors, and secondary actions

The March General Settings screenshot uses an inset modal, its own category rail, a serif heading, and grouped rows with right-aligned Change buttons. The Hub is dimmed behind it. [Settings screenshot](https://www.podfeet.com/blog/wp-content/uploads/2026/03/Wispr-Settings-General.png).

Current documentation organizes general input choices, system behavior, and account/privacy preferences separately. The bar can be repositioned and has visibility controls. [Navigation guide](https://docs.wisprflow.ai/articles/5096240724-navigating-the-wispr-flow-app-desktop-ios-and-android).

**Speak decision:** use grouped preference rows within the compact reader's settings section. Larger category navigation is unnecessary at this scope. Errors remain actionable until resolved; completion can disappear quietly. Controls required for stopping/cancelling must not depend on hover.

## Motion audit

The sources establish expansion and recording activity, but do not establish exact timing, easing, frame rate, Reduce Motion behavior, or interruption handling. Static images cannot prove smooth transitions. No animation timing is attributed to Wispr Flow here.

**Speak proposal:** preserve the existing motion contract. The alternative capsule changes width over 220 ms; new state content enters over 180 ms. Recording transitions into processing in place, then into a short confirmation. Settings content transitions in. Width changes can retarget; content entrance animations replace earlier entrance animations. Reduce Motion disables this travel. These are our starting values, not extracted Flow values. The waveform and all audio in the study are synthetic.

## Accessibility and quality risks

No firsthand VoiceOver, keyboard-order, dark-mode, contrast-preference, reduced-motion, permission-denial, or multiple-monitor testing was possible for Flow. Do not claim it passes or fails those checks from screenshots. The neutral boundaries in promotional images are subtle; actual text/control contrast needs measurement against the rendered background.

For Speak, prioritize labeled controls, text plus waveform status, visible focus, accessible hit areas, and quiet state announcements. Do not announce every level/timer update. The dark-mode palette in the alternative is an original adaptation, not an audited Flow dark theme. System appearance remains the default.

## Source conflicts and unverified areas

- The navigation guide and media kit show different Hub labels and feature groupings.
- The navigation guide routes formatting to Style → Auto cleanup; the formatting article still names Settings → System → Extras. Treat the exact current route as unverified.
- The navigation article mentions roughly six-minute desktop recordings; the first-dictation article says twenty minutes. No session limit is adopted for Speak from these conflicting statements.
- Exact fonts, native material APIs, motion curves, full first-run/paywall sequences, and runtime focus behavior were not verified. Mobile and Notetaker are secondary context, not a full separate product audit.

## Speak concept: Paper & Ink

The separate `speak-flow-study.html` translates Flow's warm neutral surfaces, dark primary controls, inset content, selective serif type, and dark recording capsule into Speak's existing 440 pt reader. It preserves local processing, TTS speed control, toggle dictation, and settings. It intentionally omits lavender because the user rejected that accent. The main Pearl & Tide design and its tokens are unchanged.

Try listening, changing speed, opening settings, and the dictation trigger followed by Stop. Text is inserted only into the study's example field. There is no real microphone, global shortcut, audio output, or cross-app insertion. This is a visual direction for comparison, not a replacement decision or native application implementation.

## Verification

Static syntax, markup IDs/references, and opaque text contrast are checked with `python3 docs/design/checks/check-preview.py speak-flow-study.html flow-study-tokens.json`. `git diff --check` checks patch whitespace. Existing Pearl & Tide checks must continue to pass.

Browser rendering and runtime interaction of the local study remain unverified: the earlier local-file preview was blocked by browser URL policy, and no workaround was attempted. Public reference images were visually inspected. The animation proposal still requires visual review and native testing before adoption.
