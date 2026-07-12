# TEST_PLAN.md — Caliper

Eight test areas, ~40 cases, traced to journeys (J*) and requirements (SRS FR/NFR).
The kernel conformance suite is the backbone: it is parameterized over `GeometryKernel`
so `MockKernel` and `OCCTKernel` (and later Parasolid) are held to the identical
contract. Phase gates G0/G1/G2 gate progression.

Case IDs: `T-<area><n>`. Areas: K kernel, C command/doc, G graph, R render, S sketch,
B boolean, X export, U UI/platform.

---

## Area K — Kernel conformance (runs against ANY GeometryKernel)

| ID | Case | Traces |
|---|---|---|
| T-K1 | `makeBox` yields non-empty, correctly-sized bounds | FR-3, J1 |
| T-K2 | `makeCylinder` bounds match radius/height | FR-4 |
| T-K3 | `tessellate` returns triangle count % 3 == 0, non-empty positions | FR-14, J1 |
| T-K4 | `boolean(.union)` of two overlapping solids → one valid solid | FR-7, J2 |
| T-K5 | `boolean(.subtract)` → solid with expected volume reduction | FR-7, J2 |
| T-K6 | `extrude` of a valid closed profile → solid; open profile throws `.invalidInput` | FR-5, J1 |
| T-K7 | `transform` translates bounds by the given vector | FR-11 (seam) |
| T-K8 | Unknown `SolidID` throws `KernelError` | FR-2 |
| T-K9 | `export(.stl/.step/.threeMF)` returns non-empty `Data` | FR-15, J1/J3 |
| T-K10 | `reset()` clears all solids | FR-1 |

> These live in `Packages/CaliperKernel/Tests`. When `OCCTKernel` lands, point the same
> suite at it — zero assertion changes (that's the guarantee).

## Area C — Command / document layer

| ID | Case | Traces |
|---|---|---|
| T-C1 | `apply(.addBox)` appends exactly one feature node and produces a SolidID | FR-16, C-3 |
| T-C2 | Kernel error during `apply` marks the feature errored, leaves prior state intact | FR-19, J2 |
| T-C3 | Undo removes the last feature and its produced solid | FR-17, G1 |
| T-C4 | Redo re-applies and reproduces the identical SolidID/bounds | FR-17 |
| T-C5 | A view path that calls a kernel directly fails a static/lint check (C-2 guard) | FR-20 |

## Area G — Feature graph / parametric re-evaluation

| ID | Case | Traces |
|---|---|---|
| T-G1 | Editing an upstream primitive param re-evaluates downstream boolean | FR-18, J3 |
| T-G2 | Graph serialize → deserialize round-trips to identical state | FR-22 |
| T-G3 | Graph may hold ≥2 root solids without error (multi-body not blocked) | FR-33 |
| T-G4 | Invalidated face reference flags for repair, does not crash | FR-19, J4 |

## Area R — Render / tessellation

| ID | Case | Traces |
|---|---|---|
| T-R1 | Scene builds from `Mesh` values only; no B-rep type reaches render | FR-14, C-1 |
| T-R2 | Tessellation tolerance changes triangle density monotonically | NFR-3 |
| T-R3 | Empty document renders without error | J1 |
| T-R4 | Selection hit-test returns the expected solid/face id | FR-24, J4 |

## Area S — Sketch & extrude (incl. face-sketching)

| ID | Case | Traces |
|---|---|---|
| T-S1 | Rectangle profile extrudes to expected dimensions | FR-5, J1 |
| T-S2 | Self-intersecting profile rejected with clear error | FR-6, J1 |
| T-S3 | Sketch snaps coplanar to a selected planar face | FR-8, J4 |
| T-S4 | Non-planar face selection rejected with guidance | FR-8, J4 |
| T-S5 | Face-anchored extrude (+) fuses; (−) cuts | FR-8, J4 |

## Area B — Boolean join/cut

| ID | Case | Traces |
|---|---|---|
| T-B1 | Subtract produces a single manifold solid | FR-7, J2 |
| T-B2 | Union of coincident-face solids yields no zero-thickness walls | FR-7, J2 |
| T-B3 | Non-overlapping subtract succeeds as a no-op (no crash) | FR-19, J2 |
| T-B4 | Toggling boolean kind re-evaluates in place | FR-18, J2 |
| T-B5 | Boolean failure preserves prior graph state | FR-19 |

## Area X — Export

| ID | Case | Traces |
|---|---|---|
| T-X1 | STL is watertight and slicer-openable | FR-15, J1 |
| T-X2 | STEP re-opens in a second CAD app with correct dimensions | FR-15, J3 |
| T-X3 | 3MF validates against the 3MF schema | FR-15 |
| T-X4 | Export of an empty document is prevented with a message | FR-19 |

## Area U — UI / platform

| ID | Case | Traces |
|---|---|---|
| T-U1 | Toolbar uses `glassEffect`/`GlassEffectContainer` per UI_SPEC | FR-27, C-7 |
| T-U2 | Every icon-only control has an accessibility label | NFR-5, C-7 |
| T-U3 | Dynamic Type scaling does not clip inspector labels | NFR-5 |
| T-U4 | App builds and launches on macOS and iPad-sim from one target | FR-25, C-6 |
| T-U5 | Input adapter maps orbit/pan/zoom identically across a pointer and a touch path | FR-26 |
| T-U6 | No view imports `CaliperKernelBridge` (dependency check) | C-1 |

---

## Phase gates

- **G0** — T-U4 + Area K (all) green on MockKernel; app launches.
- **G1** — Areas C, G(1–2,4), R, S, B, X green on **OCCTKernel**; J1–J4 pass; T-U6/T-C5
  (seam guards) pass.
- **G2** — Fillet cases (add to Area K/S in Phase 2) + T-G1 live re-eval + NFR perf
  targets; ≥3 templates dimensionally verified.

## How to run

```bash
swift test --package-path Packages/CaliperKernel        # Area K
swift test --package-path Packages/CaliperCore          # Areas C, G
xcodebuild test -scheme caliper -destination 'platform=macOS'          # R,S,B,X,U
xcodebuild test -scheme caliper -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)'
```
