# PHASES.md — What is in scope *right now*

> Claude Code: read this after `CLAUDE.md`, every session. It is the guardrail against
> the recurring failure mode — building ahead of the current phase. If a request seems
> to exceed the current phase, **stop and ask** (rule C-5).

## Current phase

**Phase 1 — Single-part MVP.** Phase 0 (scaffold + green baseline on `MockKernel`) is
the entry gate; if the workspace doesn't build on both destinations and
`KernelConformanceTests` doesn't pass, you are still finishing Phase 0.

## Cardinal rules (full text in CLAUDE.md — obey all seven)

- **C-1** Kernel seam is sacred — only `CaliperKernelBridge` touches OCCT; no hand-rolled geometry.
- **C-2** Views never call the kernel — every edit is view → `Command` → `CaliperDocument` → kernel.
- **C-3** Feature-graph-as-truth — the `FeatureGraph` is the model; render/export derive from it.
- **C-4** Docs before code — update the relevant doc before implementing a new capability.
- **C-5** Respect the phase — do not build out-of-scope features; ask when unsure.
- **C-6** One shared codebase — shared view + platform adapter, never forked views; no Catalyst.
- **C-7** First-party fidelity — HIG, Liquid Glass, SF Symbols per `UI_SPEC.md`.

## Phase map

| Phase | Theme | Gate | In scope | Explicitly OUT |
|---|---|---|---|---|
| 0 | Scaffold & baseline | G0 | Packages build; app runs on MockKernel; conformance suite green | Any feature work |
| 1 | Single-part MVP | G1 | Primitives, sketch→extrude, **boolean join/cut**, **face-sketching**, STL/STEP/3MF export, Pico template, undo/redo, one OCCT-backed kernel | Multi-body, move/transform gizmo, fillet chains, assemblies, iPadOS |
| 2 | Local ops & library | G2 | Fillet/chamfer, expanded template library (Nucleo, Uno), OCCT hardening, inspector polish | Multi-body, assemblies, iPadOS shipping |
| 3+ | Parity & iPad | — | Multi-body, parametric transform/move, direct-manipulation gizmos, iPadOS + Apple Pencil | — |

## Deferred scope (do NOT implement before its phase)

- **Multi-body / multiple root solids** — Phase 3+. The `FeatureGraph` may *hold*
  multiple roots (don't block it), but the MVP UI presents one part.
- **Move / transform gizmo (direct manipulation)** — Phase 3+. `Command.move` and
  `GeometryKernel.transform` exist as the *seam*; do not surface a gizmo UI yet.
- **Assemblies, mates, constraints** — post-parity, not roadmapped.
- **iPadOS app target / Apple Pencil input** — Phase 3+. Keep packages platform-agnostic
  so this is cheap later; do not add a second app target now.

## The seam-now-feature-later principle

Deferring a *feature* never means degrading the *architecture*. Build the seam that
makes the future feature possible (it's usually already here — `transform`, multi-root
graph), then stop at the seam. Never write code that would have to be torn out to add
multi-body or move later.

## Guardrails — common out-of-scope temptations

- A request to "add a second object" in Phase 1 → that's multi-body. Stop, confirm it's
  intended, and note it's Phase 3+.
- A request for a "drag to move" handle → that's the move gizmo. Stop; Phase 3+.
- "Make it work on iPad too" → keep logic in packages; do **not** spin up a second app
  target or Catalyst. Confirm before any platform-target change.
- "Just call OCCT directly here, it's simpler" → C-1 violation. Never.

## Shared vocabulary (use these terms exactly)

- **Solid** — one B-rep body, identified by an opaque `SolidID`.
- **Feature** — one recorded `Command` node in the `FeatureGraph`.
- **Kernel** — the geometry engine behind `GeometryKernel` (MockKernel / OCCT / Parasolid).
- **Facade** — the ObjC++→flat-C boundary in `CaliperOCCTFacade`; the only place C++ lives.
- **Command** — a user intent value (`CaliperCore.Command`). The only thing views emit.
- **Sketch** — a planar profile; **face-sketching** = a sketch anchored to a solid's face.

## Exit gates (must pass to leave a phase)

- **G0** `xcodebuild` green on macOS + iPad-sim destinations; `swift test` green for CaliperKernel.
- **G1** Journeys J1–J4 pass on an OCCT-backed kernel; export produces valid STL/STEP/3MF;
  undo/redo restores prior feature-graph state; no C-1/C-2 violations in the codebase.
- **G2** J5 (fillet) passes; ≥3 dev-board templates; OCCT operations pass the same
  `KernelConformanceTests` as MockKernel; performance NFRs met (see SRS §NFR).
