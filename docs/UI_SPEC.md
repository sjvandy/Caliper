# UI_SPEC.md — Caliper

The bar: Caliper should look and behave like a first-party app in Apple's Creator
Studio family — the restraint of Pixelmator Pro, the workspace clarity of Final Cut
Pro, the panel discipline of Logic Pro. Native materials, no custom chrome that fights
the platform. This spec is authoritative for C-7.

## 1. Design tokens

Prefer semantic system colors and materials over hard-coded values; tokens below are
the vocabulary, not literal hex to scatter through views.

- **Color:** system semantic colors (`Color.primary`, `.secondary`, `.accentColor`).
  Accent is a single brand hue used sparingly for the active tool and primary action.
  Never hard-code text/background colors that would break Dark Mode or Increase Contrast.
- **Materials:** Liquid Glass for floating chrome (see §2); `.regularMaterial`/`.thinMaterial`
  for docked panels where glass would be too busy over the 3D viewport.
- **Type:** system font, Dynamic Type text styles only (`.largeTitle`…`.caption`).
  No fixed point sizes. Inspector labels `.callout`; values `.body` monospaced-digit.
- **Spacing:** 4-pt grid (4/8/12/16/24). Toolbar item spacing 12. Panel padding 16.
- **Corner radius:** capsules for pill toolbars; 12 for panels/cards; concentric with
  the platform where views nest.
- **Iconography:** SF Symbols only, hierarchical or monochrome rendering, weight matched
  to adjacent text. Never ship a custom glyph where an SF Symbol exists.

## 2. Liquid Glass usage rules

Use glass for **floating, transient chrome over content**, not for large static regions.

- Wrap clusters of glass elements in a single `GlassEffectContainer` so they blend and
  morph as one system, rather than many independent glass blobs.
- Apply `.glassEffect(in:)` to individual floating controls (the tool pill, the
  contextual action bar). Choose the shape (`.capsule`, `.rect(cornerRadius:)`) to match §1.
- Use `.glassEffectID(_:in:)` with a namespace for controls that animate between states
  (e.g. a tool pill expanding into an options tray) so the glass morphs continuously.
- Do **not** put glass behind the primary inspector or the feature-tree panel — those
  are persistent working surfaces; use a material instead. Glass is for the layer that
  floats *over* the model.
- Attach `confirmationDialog`/menus to their triggering control so glass transitions
  originate from the right source.
- Respect Reduce Transparency and Reduce Motion: fall back to a solid material and drop
  the morph animation when those settings are on.

## 3. SF Symbols inventory (initial)

| Function | Symbol | Notes |
|---|---|---|
| Box primitive | `cube` | |
| Cylinder primitive | `cylinder` | |
| Sketch | `pencil.and.outline` | |
| Extrude | `arrow.up.to.line` | |
| Boolean union | `plus.square.on.square` | |
| Boolean subtract | `minus.square.on.square` | |
| Fillet | `scribble.variable` | Phase 2 |
| Template library | `square.grid.2x2` | |
| Export | `square.and.arrow.up` | |
| Undo / Redo | `arrow.uturn.backward` / `.forward` | |

Every icon-only control **must** carry a text label for VoiceOver (use
`Button(_:systemImage:)`), even when visually icon-only via `.labelStyle(.iconOnly)`.

## 4. Component inventory

- **Viewport** — full-bleed Metal surface (from `CaliperRender`); the model lives here.
- **Tool pill** — floating Liquid-Glass capsule, top-center, holding the active tool
  set (primitives, sketch, boolean, export). Expands into an options tray via
  `glassEffectID`.
- **Inspector** — trailing docked panel (material, not glass): parameters of the
  selected feature; edits emit `Command`s and re-evaluate the graph.
- **Feature tree / history** — leading docked panel (material): the `FeatureGraph` as an
  ordered list; selecting a node selects its feature; Phase 2+ allows parameter edits
  that re-evaluate downstream.
- **Template browser** — sheet/popover: dev-board templates; selecting one applies its
  Commands.
- **Contextual action bar** — transient glass bar near a selection (e.g. face selected →
  Sketch / Extrude / Fillet).

Layout: `NavigationSplitView` on macOS (feature tree | viewport | inspector); on iPadOS
the same split collapses adaptively, panels become slide-over. One view hierarchy, two
adaptive presentations (C-6).

## 5. Platform adaptation

- macOS: real menu bar (`Commands`), precise pointer, hover affordances, keyboard
  shortcuts for every tool. Hidden title bar; content extends to edges.
- iPadOS (Phase 3+): the same views; input via touch/Pencil through the semantic-gesture
  adapter; panels adapt to slide-over. No separate view code.

## 6. State-flow rules (authoritative)

Tool and selection state is a small explicit state machine; views render from it and
emit intents. Rules:

1. **Idle → Tool-armed** on tool selection. The armed tool is the only thing accepting
   viewport input. Escape / deselect returns to Idle.
2. **Selection precedes contextual actions.** Contextual action bar appears only when a
   valid target is selected (e.g. a planar face enables Sketch-on-face; a curved face
   does not — surface *why*, per J4 edges).
3. **One modal edit at a time.** Sketch mode, boolean target-picking, and extrude-drag
   are mutually exclusive states; entering one exits the others cleanly.
4. **Every committed state transition emits exactly one `Command`.** Transient
   in-progress manipulation (dragging an extrude distance) is local UI state; only the
   commit produces a `Command`. This keeps the feature graph clean and undo coherent.
5. **Errors don't change tool state.** A failed operation (FR-19) shows an inline
   message and leaves the user in the same tool with the prior valid model.
6. **No orphan UI for deferred features.** Do not render a move gizmo or a multi-body
   list in Phase 1/2 (C-5); the state machine simply has no such states yet.

## 7. Accessibility (non-negotiable, NFR-5)

- All controls VoiceOver-labeled; viewport exposes an accessible summary of the model.
- Dynamic Type must not clip inspector/feature-tree text; panels scroll rather than truncate.
- Honor Reduce Motion (no glass morph, no camera easing) and Reduce Transparency
  (solid materials). Provide a non-color selection cue (outline) for color-vision needs.
