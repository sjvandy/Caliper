# SRS.md — Caliper Software Requirements Specification

47 numbered requirements in "shall" form: 35 functional (FR), 12 non-functional (NFR).
Each traces to journeys (`USER_JOURNEYS.md`), tests (`TEST_PLAN.md`), and a roadmap
phase (`ROADMAP.md`). This is the requirements source of truth; update it before
implementing anything it doesn't yet cover (C-4).

Trace columns: **J** journey, **T** test, **P** phase.

## Functional requirements

### Kernel & geometry seam
| ID | Requirement | J | T | P |
|---|---|---|---|---|
| FR-1 | The system shall route all geometry operations through the `GeometryKernel` protocol. | all | T-K10 | 0 |
| FR-2 | The system shall represent solids only by opaque `SolidID` tokens outside the kernel. | all | T-K8 | 0 |
| FR-3 | The kernel shall create a box from a `BoxSpec`. | J1 | T-K1 | 1 |
| FR-4 | The kernel shall create a cylinder from a `CylinderSpec`. | J2 | T-K2 | 1 |
| FR-5 | The kernel shall extrude a closed planar profile into a solid. | J1 | T-K6,T-S1 | 1 |
| FR-6 | The system shall reject open or self-intersecting profiles with a clear error. | J1 | T-S2 | 1 |
| FR-7 | The kernel shall perform union, subtract, and intersect booleans producing valid manifold solids. | J2 | T-K4,T-K5,T-B1,T-B2 | 1 |
| FR-8 | The system shall support sketching on a selected planar face and extruding to add or cut. | J4 | T-S3,T-S4,T-S5 | 1 |
| FR-9 | Only `CaliperKernelBridge` shall link the concrete geometry engine (OCCT/Parasolid). | — | T-U6 | 0 |
| FR-10 | The system shall isolate all C++ engine contact within the ObjC++ facade behind a flat C interface. | — | — | 1 |
| FR-11 | The kernel shall expose `transform` as a recorded feature (seam for future move). | JF-move | T-K7 | 1(seam) |
| FR-12 | The kernel shall support the Parasolid swap with changes limited to the bridge + one app-shell line. | — | T-K* | 3+ |
| FR-13 | The kernel shall report bounding boxes for framing and validation. | J1 | T-K1 | 0 |

### Rendering & interaction
| ID | Requirement | J | T | P |
|---|---|---|---|---|
| FR-14 | The renderer shall consume only tessellated `Mesh` values, never B-rep data. | J1 | T-K3,T-R1 | 0 |
| FR-24 | The system shall support picking/selection of solids, faces, and edges via hit-testing. | J4,J5 | T-R4 | 1 |
| FR-25 | The application shall build and run from a single multiplatform target on macOS and iPadOS. | — | T-U4 | 0 |
| FR-26 | The system shall normalize platform input (pointer/touch/Pencil) into shared semantic gestures. | — | T-U5 | 1 |
| FR-27 | The UI shall apply Liquid Glass and SF Symbols per `UI_SPEC.md`. | all | T-U1 | 1 |

### Document, commands, parametric history
| ID | Requirement | J | T | P |
|---|---|---|---|---|
| FR-16 | Every user edit shall be represented as a `Command` value applied to `CaliperDocument`. | all | T-C1 | 0 |
| FR-17 | The system shall provide undo/redo over the feature graph. | J1 | T-C3,T-C4 | 1 |
| FR-18 | Editing a feature parameter shall re-evaluate all downstream features. | J3,J5 | T-G1,T-B4 | 1 |
| FR-19 | A failed operation shall be flagged on its feature and shall preserve the prior valid state. | J2,J4 | T-C2,T-B5,T-G4 | 1 |
| FR-20 | Views shall never call a `GeometryKernel` directly. | all | T-C5 | 0 |
| FR-21 | The feature graph shall be the single source of truth for render and export. | all | — | 0 |
| FR-22 | Documents shall serialize and deserialize the feature graph losslessly. | — | T-G2 | 1 |
| FR-23 | The system shall adopt `FileDocument`/`DocumentGroup` for a native document lifecycle. | — | — | 1 |

### Templates
| ID | Requirement | J | T | P |
|---|---|---|---|---|
| FR-28 | The system shall provide a parametric dev-board template library that emits Commands. | J3 | — | 1 |
| FR-29 | The library shall include a Raspberry Pi Pico template: 51×21×1 mm, 47.0×11.4 mm four-hole pattern. | J3 | T-K9 | 1 |
| FR-30 | The library shall include STM32 Nucleo-F446RE and Arduino Uno templates. | J3 | — | 2 |
| FR-31 | Template parameters shall be editable and shall re-evaluate the resulting body. | J3 | T-G1 | 1 |

### Export & local ops
| ID | Requirement | J | T | P |
|---|---|---|---|---|
| FR-15 | The system shall export the model to STL, STEP, and 3MF. | J1,J3 | T-K9,T-X1,T-X2,T-X3 | 1 |
| FR-32 | The kernel shall fillet selected edges by radius. | J5 | — | 2 |
| FR-33 | The feature graph shall permit multiple root solids (multi-body not architecturally blocked). | JF-multibody | T-G3 | 3+ |
| FR-34 | The system shall prevent export of an empty document. | — | T-X4 | 1 |
| FR-35 | Direct-manipulation transform (move gizmo) shall be added without changing the kernel seam. | JF-move | — | 3+ |

## Non-functional requirements

| ID | Requirement | T | P |
|---|---|---|---|
| NFR-1 | Primitive/boolean operations on MVP-scale parts shall complete within ~200 ms perceived. | — | 2 |
| NFR-2 | The UI shall remain responsive (≥60 fps interaction) during kernel work via off-main-thread actors. | — | 2 |
| NFR-3 | Tessellation quality shall be tunable by tolerance without blocking the UI. | T-R2 | 1 |
| NFR-4 | The app shall follow Apple HIG and feel first-party on each platform. | T-U1 | 1 |
| NFR-5 | The app shall meet accessibility baselines: VoiceOver labels, Dynamic Type, Reduce Motion. | T-U2,T-U3 | 1 |
| NFR-6 | Kernel operations shall degrade gracefully: no crash on invalid geometry, always a recoverable state. | T-B5 | 1 |
| NFR-7 | The codebase shall target Swift 6.2 / Swift 6 language mode with structured concurrency. | — | 0 |
| NFR-8 | Deployment targets shall be macOS 26 and iOS 26. | T-U4 | 0 |
| NFR-9 | No third-party framework beyond the geometry engine shall be added without explicit approval. | — | all |
| NFR-10 | Shared logic shall reside in platform-agnostic Swift packages; the app target shall be a thin shell. | T-U4 | 0 |
| NFR-11 | The kernel conformance suite shall pass identically across every `GeometryKernel` implementation. | T-K* | all |
| NFR-12 | Source shall follow one-type-per-file and feature-based folder organization. | — | all |

## Traceability notes

- Every G1 exit item maps to FR-5–8, FR-15–19, FR-24, FR-29 and their T-cases.
- Phase-3+ requirements (FR-33, FR-35) are stated now only to constrain the
  architecture (seam-now-feature-later); they are **not** Phase 1/2 work.
