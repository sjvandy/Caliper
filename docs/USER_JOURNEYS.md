# USER_JOURNEYS.md — Caliper

Five journeys define the MVP happy paths. Each has a step table, the expected
`FeatureGraph` state, success criteria, and edge cases. Tests in `TEST_PLAN.md` trace
to these. Journeys assume an OCCT-backed kernel (Phase 1+); on `MockKernel` the same
steps run but produce placeholder geometry.

Legend for graph state: `[n: command → SolidID]`.

---

## J1 — Sketch, extrude, export (the core path)

A newcomer makes their first part and exports it to print.

| # | User action | System response |
|---|---|---|
| 1 | Launch app | Empty document, base plane visible, Liquid-Glass toolbar |
| 2 | Pick Sketch, draw a 40×20 mm rectangle on the base plane | Live sketch profile shown |
| 3 | Confirm sketch, choose Extrude, drag/enter 10 mm | Solid appears; camera frames it |
| 4 | Export ▸ STL, choose location | `.stl` written; save panel confirms |

**Graph state after step 3:** `[0: extrudeSketch(rect,10) → S1]`
**Success:** a 40×20×10 mm solid renders; exported STL is a valid closed mesh a slicer accepts.
**Edges:** open/self-intersecting profile → clear error, no solid; zero/negative distance → rejected with message.

---

## J2 — Boolean join/cut (the pipeline that was broken)

Make a pocket by subtracting one primitive from another.

| # | User action | System response |
|---|---|---|
| 1 | Add Box 40×40×20 mm | Solid S1 |
| 2 | Add Cylinder r=8, h=25 mm, positioned over S1 | Solid S2 (tool) |
| 3 | Select Subtract, target S1, tool S2 | S1 gains a cylindrical pocket; S2 consumed |
| 4 | Switch the same features to Union | Bodies merge into one solid instead |

**Graph state after step 3:** `[0: addBox → S1] [1: addCylinder → S2] [2: boolean(subtract,S1,S2) → S3]`
**Success:** subtract yields a single valid solid with a pocket; union yields a single fused solid; toggling kind re-evaluates without re-authoring; result passes manifold check.
**Edges:** non-overlapping tool → subtract is a no-op that still succeeds (no crash); coincident faces → tolerant boolean, no zero-thickness walls; boolean failure → feature marked errored, prior state preserved.

---

## J3 — Dev-board template → export

Drop in a Raspberry Pi Pico footprint and export a matching part.

| # | User action | System response |
|---|---|---|
| 1 | Open Template browser, choose Raspberry Pi Pico | Template's Commands applied; board body appears |
| 2 | Adjust a parameter (e.g. thickness) in the inspector | Feature graph re-evaluates; body updates |
| 3 | Export ▸ STEP | `.step` written |

**Graph state after step 1:** the template's Command list, each producing a `SolidID`.
**Success:** body is 51×21×1 mm with the 47.0×11.4 mm four-hole mounting pattern; parameter edit re-evaluates correctly; STEP opens in another CAD app with correct dimensions.
**Edges:** parameter driven out of valid range → clamp + message; template applied into a non-empty doc → Phase 1 presents one part (multi-body is Phase 3+), so confirm/replace rather than silently add a second body.

---

## J4 — Face-sketching (the pending UX issue)

Sketch on an existing solid's face and extrude a boss/cut.

| # | User action | System response |
|---|---|---|
| 1 | With solid S1 present, choose Sketch, click a planar face of S1 | Sketch plane snaps to that face |
| 2 | Draw a circle on the face | Profile shown on the face |
| 3 | Extrude +5 mm (add) | Boss added and fused to S1 |
| 4 | Repeat with −3 mm (cut) | Pocket cut into S1 |

**Graph state after step 3:** `[…S1] [k: extrudeSketch(faceProfile,+5) → S2] [k+1: boolean(union,S1,S2) → S3]`
**Success:** the sketch is coplanar with the selected face; add fuses, cut subtracts; downstream re-evaluates if S1's upstream changes.
**Edges:** curved/non-planar face selected → reject with guidance; profile crossing the face boundary → clip or reject clearly; face reference invalidated by an upstream edit → feature flags for repair rather than crashing.

---

## J5 — Fillet an edge (Phase 2)

Round an edge for printability/ergonomics.

| # | User action | System response |
|---|---|---|
| 1 | Select an edge (or "all edges") on S1 | Edge highlighted |
| 2 | Apply Fillet, radius 2 mm | Edge rounded; solid updated |
| 3 | Edit radius to 4 mm in inspector | Re-evaluates live |

**Graph state after step 2:** `[…S1] [m: fillet(S1, r=2) → S2]`
**Success:** valid rounded solid; radius edit re-evaluates; radius larger than local geometry allows → graceful error, prior solid kept.
**Edges:** radius ≥ adjacent face size → operation fails cleanly; filleting an already-filleted edge → tolerant or clear rejection.

---

## Future journey (Phase 3+, documented so the architecture doesn't box it out)

- **JF-move** — select a body, drag a gizmo to translate/rotate; recorded as
  `Command.move` / `GeometryKernel.transform`, fully parametric. Seam exists today; UI
  and gizmo are Phase 3+.
- **JF-multibody** — multiple independent bodies in one document with a body list. The
  `FeatureGraph` already tolerates multiple roots; UI is Phase 3+.
