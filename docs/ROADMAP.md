# ROADMAP.md — Caliper

Sequence of work, each phase closing on a concrete, testable gate. `PHASES.md` says
what's in scope *now*; this says the order and the exit criteria. North star is
Shapr3D functional parity — the MVP is Milestone 1 on that path, not the ceiling.

---

## Phase 0 — Scaffold & green baseline

**Goal:** an openable workspace that builds and runs on both destinations with the
`MockKernel`, before any real geometry.

Work:
- Xcode multiplatform app target wired to the local packages (see `SETUP.md`).
- `GeometryKernel` protocol, value types, `MockKernel`, conformance test suite.
- Command → `CaliperDocument` → kernel pipeline stubbed and exercised end-to-end.
- Placeholder Metal viewport + Liquid-Glass toolbar.

**Exit gate G0 (all must pass):**
1. `xcodebuild -scheme caliper -destination 'platform=macOS' build` → success.
2. `xcodebuild ... -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' build` → success.
3. `swift test --package-path Packages/CaliperKernel` → `KernelConformanceTests` green.
4. App launches; toolbar "Box" button appends a box feature (visible in logs / mock bounds).

---

## Phase 1 — Single-part MVP

**Goal:** a person can model one part from scratch and export it for printing, on a
real (OCCT-backed) kernel.

Work, roughly in order:
1. **OCCT integration.** Fill `CaliperOCCTFacade` (`.mm` + xcframework), implement
   `OCCTKernel` primitives + tessellation. Flip `CaliperApp` to `OCCTKernel()`.
2. **Sketch → extrude.** Rectangle/circle profile on a base plane → `extrude` → solid.
3. **Face-sketching.** Sketch anchored to an existing solid's planar face → extrude
   (add/cut). (Fixes the pending face-sketch UX issue.)
4. **Boolean join/cut pipeline.** `union` / `subtract` wired through `Command.boolean`,
   with correct feature-graph recording. (Fixes the pending join/cut UX issue.)
5. **Export.** STL, STEP, 3MF via `GeometryKernel.export`, with a save panel.
6. **Undo/redo** over the feature graph.
7. **Pico template.** `DevBoardTemplate.raspberryPiPico` produces a correct body
   (51×21×1 mm, 47.0×11.4 mm four-hole pattern) via Commands.

**Exit gate G1:**
1. Journeys **J1–J4** pass on `OCCTKernel` (see `USER_JOURNEYS.md`).
2. Exported STL/STEP/3MF open cleanly in a slicer / a second CAD app.
3. Undo restores the exact prior `FeatureGraph` state; redo re-applies it.
4. Static check: no code outside `CaliperKernelBridge` imports OCCT; no view calls a
   `GeometryKernel` (C-1/C-2 clean).
5. `KernelConformanceTests` passes against `OCCTKernel`, unchanged from MockKernel.

---

## Phase 2 — Local ops & template library

**Goal:** rounding/finishing operations and a real template library; production-quality
OCCT robustness.

Work:
- **Fillet / chamfer** (`Command.fillet`, edge selection).
- **Template library**: STM32 Nucleo-F446RE, Arduino Uno (≥3 boards total).
- **OCCT hardening**: tolerance handling, failed-operation recovery, non-manifold guards.
- **Inspector polish**: parameter editing re-evaluates the feature graph live.

**Exit gate G2:**
1. Journey **J5** (fillet) passes.
2. ≥3 dev-board templates produce dimensionally correct bodies.
3. Editing an upstream feature parameter re-evaluates all downstream features correctly.
4. Performance NFRs met (see `SRS.md` NFR-1…NFR-6).

---

## Phase 3+ — Parity & iPad (on the horizon, not yet scheduled in detail)

- **Multi-body** (multiple root solids, body list UI).
- **Parametric transform / move** with a direct-manipulation gizmo.
- **iPadOS + Apple Pencil**: add platform input adapter + (if warranted) a second thin
  app target sharing all packages. Decision deferred until the macOS app is solid.
- Progressive march toward full Shapr3D functional parity.

> Do not pull Phase 3+ work forward without an explicit decision to re-scope (and a
> corresponding update to this file and `PHASES.md`). If asked, present the two paths
> (staged vs. pull-forward) with tradeoffs.
