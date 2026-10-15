# Ananta artwork

The hero was generated with the built-in `image_gen` tool and saved into the app at `Ananta/Resources/Assets.xcassets/CosmicLotus.imageset/cosmic-lotus.png`. No CLI fallback or API key was used. The original generated image remains in Codex’s generated-image directory; the app uses its bundled copy.

Exact generation prompt:

> Use case: stylized-concept. Asset type: hero illustration for a premium native iOS learning app about Hinduism named Ananta. Create a luminous antique gold lotus floating on a dark midnight teal cosmic ocean, fine delicate celestial orbital rings and tiny gold stars around it, distant subtle temple-like mountain silhouette, inspired by intricately painted Indian manuscript borders and engraved astronomical charts. Sophisticated museum editorial illustration, tactile hand-painted pigment, luminous warm ochre and muted aged brass over deep ink navy and teal. Wide landscape composition 1536x1024. Lotus centered in right-middle portion with generous dark negative space at left and upper left for UI copy that will be added in code. Dense beautiful detailing in the flower, restrained composition elsewhere. Reverent contemplative educational mood. Do not show deity figures, people, any text, letters, symbols resembling writing, watermarks, app interfaces or device mockups. Must be an artwork background, no rounded rectangle or border.

The icon is drawn with Core Graphics by `Scripts/make_icon.swift`. The cosmic diagrams are interactive SwiftUI Canvas compositions; they are not flattened generated images. UI screenshots in `Docs/Screenshots` are captures of the running native application.
