# Speak design language — Pearl & Tide

Selected direction, 2026-09-13. The user chose Pearl & Tide after comparing it with Paper & Ink. This defines the native Mac application's identity and interaction standards; it does not implement the native interface. Canonical values: [tokens.json](tokens.json). The interactive companion preview is `speak-theme.html` in this directory.

## Character

Quiet, precise, and tactile. Pearl and graphite establish the surface; a cool teal accent identifies the main action and active controls. Depth comes from native materials, spacing, and restrained shadows. Content gets the most visual space. Prefer the system's controls, window behavior, and typography so Speak feels at home on the Mac.

The application is a small native Swift/SwiftUI companion. Raycast and, later, Alfred are control layers that retain their host's design conventions. Do not recreate Speak's window styling inside Raycast. Share names, status language, icons where supported, and the same underlying behavior.

## Color

| Semantic role | Light | Dark | Use |
| --- | --- | --- | --- |
| Window | `#F5F5F7` | `#191A1F` | Pearl / graphite base |
| Content | `#FFFFFF` | `#22232A` | Reading and text input |
| Primary text | `#1C1D25` | `#F4F4FA` | Main labels and content |
| Secondary text | `#646572` | `#B6B7C5` | Supporting labels; not faint disabled text |
| Tide accent | `#006C75` | `#8CDEE5` | Primary action, active progress, focus |

Use the paired `onAccent` color for filled controls: white in light mode, deep teal `#092E32` in dark mode. Do not place white text on the pale dark-mode accent. Tint a small number of functional elements; do not wash every panel with the accent.

Recording is semantic rose (`#C33142` / `#FF8C99`) paired with a microphone/square icon and explicit Recording label. Success and warning have separate green and amber tokens. State must never depend on color alone. Dividers are structural and subtle; essential control outlines use system contrast behavior, not the decorative divider token.

**Tide is the default accent.** The user rejected the previous light-purple direction; do not retain Iris as the default or offer it as a design alternative in the MVP.

Hex values describe the brand palette and opaque fallback surfaces. Prefer native semantic foreground/background colors for standard SwiftUI/AppKit controls. Material appearance belongs to the OS, not a fixed RGBA recipe. System appearance is the default; the app must also work in light and dark modes.

## Materials and macOS compatibility

The reflective finish the user described is Apple's **Liquid Glass**. Use the regular variant selectively for the floating playback/recording control and appropriate native chrome. The reading/editor surface stays opaque or uses a standard content material. Avoid clear glass over text. Apple describes glass as the functional layer for controls/navigation and advises against using it in the content layer. [Apple materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials).

Build standard bars, sheets, buttons, sliders, and popovers with native components before adding custom glass effects. Where a custom glass container is necessary, availability-gate it for macOS 26+, using the supported SwiftUI glass APIs. Do not layer custom shine, heavy blur, or multiple glass surfaces over native glass. [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass), [custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).

The current development Mac is on macOS 15.7.7. Keep macOS 14+ support with an NSVisualEffectView/SwiftUI material fallback and the same layout, controls, and palette. No OS upgrade is required for the MVP. True Liquid Glass must be verified on a supported system; the browser preview approximates appearance and cannot verify native refraction or system accessibility adaptations.

## Type, geometry, and iconography

Use SF Pro through the system font APIs. The palette's intended hierarchy is 14 pt section titles, 16 pt reading text, 13 pt controls/body, and 12 pt supporting labels; 11 pt is the floor. Use regular weight for reading and semibold for hierarchy. Let system controls keep their native sizing. Reading text uses generous line spacing, a comfortable line length, and adjustable size in future settings; never truncate dictated text.

Use a 4 pt spacing foundation with 8/12/16/24/32 pt steps. Keep native window corner radii and traffic lights under system control. Custom fields use roughly 10 pt radii, content groupings 10 pt, and the compact recorder/player a capsule. Avoid rounding every row into a separate card. One subtle separation shadow is enough for floating controls.

Use SF Symbols in the actual app: `waveform`, `mic`, `play.fill`, `pause.fill`, `stop.fill`, `slider.horizontal.3`, and `checkmark` where appropriate. Labels and familiar icons carry meaning. The preview uses approximate icon equivalents, not production assets. A final app icon is a separate design deliverable; do not ship a generic microphone as an unreviewed final brand mark.

## Surfaces

| Surface | Purpose | Interaction |
| --- | --- | --- |
| Menu-bar entry | Open Speak, show current state, stop active work | Native menu/popover; status readable without color |
| Compact floating control | Recording indicator or playback with live speed | Non-activating presentation; preserve the target field |
| Main window | Compact text reader and recovery when needed | Reader by default; no routine Dictate screen, hero heading, or sidebar |
| Settings | Voice, speed preference, formatting, shortcuts, startup | Native grouped controls; permission/model setup lives here when needed |

The main window is optional for everyday dictation. A global shortcut starts recording directly, shows a small waveform pill near the bottom center of the active screen, and preserves the focused text field. Pressing the same shortcut again stops capture, transcribes, inserts the result, briefly confirms success, and dismisses the pill. Escape cancels without insertion. The waveform reflects microphone energy only while recording. Preparing/transcribing use a truthful status label; idle has no persistent pill.

Target a 440 pt wide reader with 12 pt content padding and approximately 300 pt initial height; permit resizing for longer text. The recording pill starts around 280 × 44 pt, with room to grow for accessibility and localized labels. The reading window has text, voice/status, playback, and live speed controls. A gear opens a dedicated Settings section with a back action. Settings include a configurable shortcut, Plain/Spoken lists formatting, speed memory, appearance, and voice. The preview shortcut is illustrative (Control–Option–Space); production needs a shortcut recorder and conflict validation. No global shortcut is registered by this preview.

The full window is a workspace the user opens intentionally. Remember window size and location. Closing the window should not quit an ongoing background session; quitting the app must stop microphone capture and playback.

## Interaction contract

**Dictation:** Idle → Preparing (only when needed) → Recording → Transcribing → Inserted or Ready to copy. The user sees Recording only after actual capture begins. Show an elapsed timer and always provide Stop and Cancel. The indicator must not steal focus. Preserve original text alongside formatted text, and never insert after cancellation. If the target field is unavailable or changed, offer copy/retry instead of silently guessing.

**Reading:** Text entry → Preparing speech → Playing ↔ Paused → Finished. Keep text and current position stable when the speed changes. Present a continuous slider, a numeric rate, and keyboard adjustments. Support 0.5–2.0× initially with 0.1× keyboard steps. Apply changes during dragging, with the existing 150 ms rate ramp. Do not require releasing the slider or regenerating audio. Pause/resume is a proposed native UI behavior, not yet exposed by the command-line prototype.

**Responsiveness:** Button press feedback should be immediate, independent of inference. Acknowledge an operation within 100 ms as a design target; never manufacture a ready state to meet it. Show clear model warm-up progress when applicable. Preserve content during errors. A normal successful paste needs a brief confirmation, not a modal dialog. Error messages state the problem and a recovery action.

**Keyboard:** Support standard Tab navigation, visible focus, keyboard access to every button/slider, Escape to cancel/dismiss the current transient UI, and the app's chosen global dictation shortcut. Shortcut assignments must be configurable and conflict-checked. Avoid commandeering common editing shortcuts. An accidental second start during transcription must not create a second insertion.

**Formatting:** Label the current option accurately: Plain or Spoken lists. Do not advertise automatic structural understanding while the implementation only recognizes explicit cues. The preview uses demonstration text; it performs no recording, inference, paste, or audio playback.

## Motion and accessibility

**State changes have visual continuity.** Every user-visible change of UI state must have a deliberate transition that communicates what changed, using supported native animation where available. Treat motion as part of the interaction contract, not optional polish. Preserve the identity and position of the control as its role changes; avoid abrupt replacement of unrelated views. This principle covers meaningful state changes, not a separate animation for every timer tick or streamed character.

| State change | Intended transition |
| --- | --- |
| Shortcut → recording | Reveal the compact pill with a gentle fade/expansion; when a visible trigger exists, transition that control into the pill. Bring in the waveform as capture begins. |
| Recording → transcribing | Settle the waveform and transition its content to processing status within the same pill. |
| Transcribing → inserted or recovery | Transition to a confirmation or actionable recovery state; success briefly settles before the pill fades away. Errors remain available until resolved or dismissed. |
| Playing ↔ paused; speed adjustment | Smoothly change the control's icon/state while preserving text and playback position; ease speed changes without restarting audio. |
| Reader ↔ settings; cancel/dismiss | Use a short, reversible panel transition or exit animation, keeping focus and spatial context predictable. |

Transitions must be interruptible and retarget from the current presentation when state changes quickly. Never queue obsolete animations, delay capture/insertion/cancellation to finish an animation, or show success before it occurs. Keep controls usable during transitions. In Raycast, use host-supported transitions and state feedback rather than promising custom animation its API cannot provide.

Use approximately 100 ms feedback, 150 ms speed easing, 180 ms state transitions, and 220 ms panel transitions. These are starting tokens, not overrides for system-owned animation. Prefer small opacity/position changes, with minimal spring overshoot. No decorative idle pulsing, animated wallpaper, or constant glow. A real recording waveform must reflect microphone energy; a quiet microphone gets a quiet waveform.

For Reduce Motion, replace spatial/morph transitions with a restrained crossfade where appropriate, or immediate explicit state feedback when needed. Accessibility takes precedence over animation; labels and announcements must communicate the same change. The existing HTML study remains unchanged and does not yet demonstrate this full transition contract.

Respect Reduce Motion (remove travel, spring/morph effects, and decorative animation), Reduce Transparency (solid semantic surfaces), and Increase Contrast (stronger separators and system control outlines). These settings are supported by native Liquid Glass; custom elements must be checked too. [Apple Liquid Glass accessibility](https://developer.apple.com/videos/play/wwdc2025/219/).

Use VoiceOver names and values for controls, announce state changes once, and avoid announcing the timer every frame. Keep focus visible. Target at least 4.5:1 for normal text and 3:1 for essential non-text controls on the actual background. Pointer targets should follow native macOS sizing; expand custom targets toward 44 pt for coarse-pointer/accessibility contexts. Avoid tiny hit areas around otherwise large capsule controls.

## Design verification before shipping

Review light/dark appearances, busy/quiet desktop backgrounds, transparency reduction, increased contrast, reduced motion, keyboard-only use, VoiceOver, window resizing, long text, missing permissions, model loading, and insertion recovery. Verify that speed changes preserve audio position and do not stop speech. Test focus restoration with the compact control over common text fields. Native Liquid Glass and the macOS 15 fallback both need direct testing; a preview is not evidence that the production UI passes these checks.

Review each meaningful state transition for continuity, including rapid start/stop/cancel and opening/closing settings mid-playback. Verify that animations can be interrupted, never hold up the underlying action, preserve focus, and have a suitable Reduce Motion alternative.

Next implementation: build the minimal SwiftUI companion and a working shortcut-to-dictation-to-insertion flow with a non-activating waveform control. Apply the selected visual direction and motion contract. Actual Mac UI code is not added by this design task.

## Raycast TTS parity

Users can enter text and control playback entirely inside Raycast. The Swift companion owns the session, keeping playback alive when Raycast closes. Both entry points share voice, speed, playback state, pause/resume, and stop behavior. Opening the app should reveal the existing session, not start a second one.

Raycast renders its supported native components, so functional parity does not imply embedding the custom SwiftUI player. Use `Form.TextArea` for text and actions/shortcuts plus supported rate controls for playback; rate changes must update the existing audio session. Its documented form components do not include a custom continuous slider, so exact slider parity remains an implementation constraint. [Raycast UI](https://developers.raycast.com/api-reference/user-interface), [Form API](https://developers.raycast.com/api-reference/user-interface/form).

Revision 2 records the user’s compact-window, shortcut-first dictation, dedicated settings, and non-purple accent preferences. This remains a design revision; native app implementation is the next phase.
