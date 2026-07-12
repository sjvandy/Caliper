# AGENTS.md — Caliper

> Read this file at the start of every session. Then read `docs/PHASES.md` to learn
> what is in scope **right now**. Do not begin work until you know the current phase.

## What Caliper is

Caliper is a native **macOS + iPadOS** CAD application — a Shapr3D-style **direct
modeler with adaptive parametric history** — written entirely in **Swift/SwiftUI**
with **Metal** rendering. It should feel like a first-party app in Apple's Creator
Studio suite (Liquid Glass, SF Symbols, full HIG compliance), taking UX cues from
Pixelmator Pro, Final Cut Pro, and Logic Pro.

**North star:** functional parity with Shapr3D. That is the destination, and the
architecture must never preclude it (see "Scope" below for how that squares with the
staged build).

**Target user:** newcomers to 3D printing who need an accessible but capable modeler.

## Platform strategy (decided)

**One codebase. One multiplatform SwiftUI app target. All real logic in local Swift
packages.** Not two apps. Not Mac Catalyst.

- The app target (`App/`) is a thin shell. Everything of substance lives in
  `Packages/` and is platform-agnostic.
- macOS and iPadOS are served by the **same** SwiftUI views, differing only through
  small platform adapters (`#if os(...)`) — chiefly the **input layer** (precise
  pointer + menu bar + keyboard modifiers on macOS; multitouch + Apple Pencil on
  iPadOS). Normalize both into semantic gestures behind one abstraction; never fork a
  whole view.
- **Do not use Mac Catalyst.** It produces an iPad app wearing a Mac costume and will
  not deliver the first-party macOS feel (native menu bar, window management, precise
  pointer) that is a product requirement.
- Splitting into two app targets later is a cheap, reversible move *because* all logic
  is package-ised. We are deliberately deferring that decision, not foreclosing it.

## The one rule that outranks all others: the kernel seam

Caliper never hand-rolls geometry. All B-rep math goes through the
`GeometryKernel` protocol (`Packages/CaliperKernel`). OpenCASCADE (OCCT 7.9.x, LGPL)
is today's engine; **Parasolid is the planned swap.** That swap must cost one line
(`CaliperApp.swift`, where the concrete kernel is constructed).

- Only **`Packages/CaliperKernelBridge`** may link OCCT, and only through the
  Objective-C++ → flat-C facade (`CaliperOCCTFacade`). C++ never reaches Swift.
- Everything else depends on `CaliperKernel` (the protocol), **never** the bridge.
- If you are about to import a kernel type outside the bridge, or call OCCT from a
  view, or add geometry math in Swift — stop. That is the mistake that makes the
  Parasolid migration impossible.

## Module map

```
App/                     Thin @main shell. The ONE place the concrete kernel is chosen.
Packages/
  CaliperKernel          Pure-Swift GeometryKernel protocol + value types + MockKernel.
                         Depends on NOTHING. The seam.
  CaliperKernelBridge    OCCT-backed kernel. ObjC++/C facade + Swift conformance.
                         The ONLY package that may link OCCT / Parasolid.
  CaliperCore            Document model, FeatureGraph (parametric history), Command
                         (intent) layer, undo/redo. Depends on CaliperKernel only.
  CaliperRender          Metal rendering. Consumes ONLY Mesh values from the kernel.
  CaliperUI             SwiftUI views (shared + platform-conditional). Emits Commands.
  CaliperTemplates       Parametric dev-board template library (Pico first).
Vendor/OCCT/             Prebuilt OCCT.xcframework (binaryTarget).
docs/                    ARCHITECTURE, ROADMAP, USER_JOURNEYS, TEST_PLAN, SRS, UI_SPEC, PHASES.
```

## Cardinal rules

- **C-1 — Kernel seam is sacred.** Nothing but `CaliperKernelBridge` touches OCCT.
  Everything else talks to the `GeometryKernel` protocol. No hand-rolled geometry, ever.
- **C-2 — Views never call the kernel.** Every edit flows view → `Command` →
  `CaliperDocument` → kernel. No exceptions. This is what gives us undo, parametric
  history, and future scripting for free.
- **C-3 — Feature-graph-as-truth.** The parametric model *is* the `FeatureGraph`.
  Render, export, and inspection all derive from it. Don't cache geometry as truth.
- **C-4 — Docs before code.** These docs are the source of truth. A capability not in
  the docs will be built wrong or not at all. Update the relevant doc **before**
  implementing; treat that as mandatory, not optional.
- **C-5 — Respect the phase.** Read `docs/PHASES.md`. Do not build out-of-scope
  features (see "Scope"). If a request seems to exceed the current phase, say so and
  ask before proceeding.
- **C-6 — One shared codebase.** Prefer a shared view + platform adapter over forking.
  Kernel/core/render/templates packages must stay platform-agnostic.
- **C-7 — First-party fidelity.** Match the HIG. Liquid Glass and SF Symbols per
  `docs/UI_SPEC.md`. If it wouldn't ship in an Apple app, it doesn't ship in Caliper.

## Scope: how "Shapr3D parity" and "single-part MVP" coexist

There is one live tension worth stating plainly. The long-term vision is full parity
(multi-body, assemblies eventually, full direct manipulation). The near-term build is
a deliberately narrow **single-part MVP** used as an engineering checkpoint.

These are **not** in conflict:

- **Milestone 1 (MVP)** is a *checkpoint on the path*, not the ceiling. It proves the
  seam, the command pipeline, render, and export end-to-end on one body.
- **Multi-body and parametric transform (move) are IN the product vision.** The
  `FeatureGraph` and `GeometryKernel` are already designed not to preclude them
  (the graph can own multiple root solids; `transform` is a first-class recorded
  feature, not a one-shot mutation).
- What "respect the phase" (C-5) means: **don't *implement* post-MVP features early**,
  but never *architect in a way that blocks them*. When in doubt, build the seam now,
  the feature later.

`docs/PHASES.md` is authoritative for what to implement this session. `docs/ROADMAP.md`
is authoritative for the sequence. If a user request conflicts with the current phase,
surface it and offer the two coherent paths rather than silently picking one.

## Conventions

- **Swift 6.2**, Swift 6 language mode, modern structured concurrency. Deployment
  target **macOS 26 / iOS 26**.
- **SwiftUI-first. Avoid UIKit/AppKit** unless a capability genuinely requires it (e.g.
  the Metal view host) — and ask first.
- **No third-party frameworks** without asking. OCCT is the sole heavyweight dependency
  and it is already decided.
- **One type per file.** Folder layout follows features/modules, not type kind.
- Concurrency: the kernel and document are actors; UI models are `@MainActor`
  `@Observable`. Value types cross the kernel seam; never share engine handles.
- Prefer `foregroundStyle`, `Button(_:systemImage:)`, `.glassEffect`, `ContentUnavailableView`,
  and other current APIs. Accessibility (Dynamic Type, VoiceOver, Reduce Motion) is not
  optional — every icon-only control needs a label.

## Definition of done (per change)

1. Builds clean on both macOS and iPadOS destinations.
2. New kernel behaviour passes `KernelConformanceTests` (the suite runs against *any*
   `GeometryKernel`, so MockKernel and OCCT are held to the same contract).
3. No cardinal-rule violation (esp. C-1, C-2).
4. Relevant doc updated (C-4).
