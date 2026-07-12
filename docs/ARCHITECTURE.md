# ARCHITECTURE.md — Caliper

The one idea this whole architecture protects: **Caliper never depends on a specific
geometry engine.** Everything flows from that. OpenCASCADE today, Parasolid later, and
the swap must cost one line.

## Layer diagram

```
                        ┌───────────────────────────────┐
                        │  App/  (thin @main shell)      │  ← the ONE place a
                        │  chooses the concrete kernel   │    concrete kernel is named
                        └───────────────┬───────────────┘
                                        │ emits Commands
             ┌──────────────────────────▼──────────────────────────┐
             │  CaliperUI  (SwiftUI, shared + platform adapters)     │  C-2: views emit
             │  ModelEditorView · EditorModel · inspector · panels   │  Commands only
             └──────────────────────────┬──────────────────────────┘
                                        │ Command
             ┌──────────────────────────▼──────────────────────────┐
             │  CaliperCore                                          │
             │  Command · FeatureGraph (truth) · CaliperDocument     │  C-3
             └───────────┬───────────────────────────┬──────────────┘
                         │ Mesh                       │ any GeometryKernel
             ┌───────────▼───────────┐   ┌────────────▼─────────────────────────┐
             │  CaliperRender        │   │  CaliperKernel  (the SEAM)            │
             │  Metal · Mesh only    │   │  GeometryKernel protocol + values     │  C-1
             └───────────────────────┘   │  MockKernel (dependency-free)         │
                                          └────────────┬─────────────────────────┘
                                                       │ conforms
                                          ┌────────────▼─────────────────────────┐
                                          │  CaliperKernelBridge                  │
                                          │  OCCTKernel (Swift) ── flat C ──►      │
                                          │  CaliperOCCTFacade (.mm, ObjC++)  ──► OCCT xcframework
                                          └───────────────────────────────────────┘
```

Dependency direction is strictly downward. Nothing above `CaliperKernel` may import
`CaliperKernelBridge` or OCCT. `CaliperRender` sees only `Mesh`.

## The kernel seam

`Packages/CaliperKernel/Sources/CaliperKernel/GeometryKernel.swift` defines the entire
contract. Its shape (authoritative — keep code and this doc in sync):

- Lifecycle: `reset()`
- Primitives: `makeBox(BoxSpec)`, `makeCylinder(CylinderSpec)`
- Sketch→solid: `extrude(ExtrudeSpec)`
- Booleans: `boolean(BooleanSpec)` with `.union` / `.subtract` / `.intersect`
- Local ops: `fillet(FilletSpec)`
- Transform: `transform(TransformSpec)` — a *recorded feature*, not a one-shot mutation
- Output: `tessellate(id, tolerance) -> Mesh`, `bounds(id) -> BoundingBox`
- Export: `export(id, format) -> Data` (`.stl` / `.step` / `.threeMF`)

Seam rules:
1. **Value types only cross the boundary.** `SolidID` is an opaque, kernel-owned token;
   callers never inspect it. No OCCT handles, no `TopoDS_Shape`, ever leak upward.
2. **Operations are pure w.r.t. Caliper state.** They take IDs + params, return a new
   ID or throw `KernelError`. The kernel owns its geometry store.
3. **Tessellation is the only pixel path.** The renderer consumes `Mesh` and nothing else.
4. The kernel is an **actor** (`MockKernel`, `OCCTKernel`) — geometry mutation is
   serialized; callers `await`.

## Why the ObjC++ → flat-C facade

OCCT is a large C++ library; Swift's C++ interop is workable but brittle at that scale,
and Parasolid is a C API. So we standardize on a **flat C boundary**:

- `CaliperOCCTFacade` is an ObjC++ target. Its `.mm` implementation is the **only**
  place OCCT's C++ headers are `#include`d. It exposes a plain C header
  (`CaliperOCCTFacade.h`): opaque `uint64` handles, `bool`-returning functions with
  out-params, explicit free functions. No C++ types, no exceptions cross the line.
- `OCCTKernel` (Swift) imports that C header and adapts it to `GeometryKernel`,
  translating `false` returns into `KernelError`.

This means the day Parasolid arrives, we write a second facade with the *same* flat-C
shape and a `ParasolidKernel` conforming to the *same* protocol. Everything above is
untouched. That is the whole point of the extra indirection.

## Command / feature-graph flow (C-2, C-3)

1. A view calls `EditorModel.send(_ command:)` — the only thing a view does.
2. `EditorModel` (`@MainActor @Observable`) forwards to the actor `CaliperDocument`.
3. `CaliperDocument.apply(_:)` appends a `FeatureNode` to the `FeatureGraph` (the
   source of truth), then evaluates it against `any GeometryKernel`, storing the
   produced `SolidID` back on the node.
4. Render and export derive from the graph's produced solids via `tessellate`/`export`.

Editing an upstream feature re-evaluates downstream nodes (parametric history). Undo/redo
is graph-state restoration. Because every edit is a `Command` value, scripting and
automation later fall out for free.

## Render abstraction

`CaliperRender` owns the Metal view (an `MTKView`/`CAMetalLayer` host — the one place
UIKit/AppKit is acceptable, and only for the view host). It receives `RenderScene`
built from `Mesh` values. It never sees B-rep data. Camera, hit-testing for selection,
and the pipeline live here and are shared across platforms.

## Input abstraction (the real cross-platform seam)

macOS and iPadOS differ mainly in *input*, so that is where the `#if os(...)` lives —
behind one abstraction, not in forked views:

- macOS: precise pointer, hover, scroll/zoom, modifier keys, menu-bar commands.
- iPadOS: multitouch, Apple Pencil (hover on Pro, pressure, tilt, double-tap, squeeze).

Both are normalized into **semantic gestures** (e.g. `tap-select`, `orbit`, `pan`,
`extrude-drag`) consumed by shared view logic. Adding iPadOS = implementing the
adapter, not rewriting the editor. This is why C-6 forbids forked views and Catalyst.

## Concurrency model

- Kernels and `CaliperDocument`: actors. Geometry work is off the main thread.
- UI: `@MainActor`, `@Observable` models; SwiftUI observes.
- Swift 6 language mode; `Sendable` value types cross the seam.

## The kernel swap procedure (Parasolid, later)

1. Build `CaliperParasolidFacade` exposing the same flat-C header shape.
2. Add `ParasolidKernel: GeometryKernel` in the bridge, calling that facade.
3. Ensure it passes the unchanged `KernelConformanceTests`.
4. Change one line in `CaliperApp.swift`: `EditorModel(kernel: ParasolidKernel())`.

If that procedure ever requires touching a view, a `CaliperCore` type, or the renderer,
the seam has been violated somewhere — find it and fix it.
