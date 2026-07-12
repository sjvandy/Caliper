# Caliper

Caliper is a native CAD modeling application built for Apple platforms with Swift,
SwiftUI, and Metal. Its goal is to make precise 3D modeling approachable for newcomers
while growing into a capable direct modeler with adaptive parametric history.

The project is designed as a first-party Apple experience: one shared Swift codebase,
native interaction on macOS and iPadOS, a Metal-powered viewport, and no Mac Catalyst.

> [!NOTE]
> Caliper is in early development. The current milestone is a single-part MVP; it is
> not yet ready for production modeling work.

## Vision

Caliper aims to provide a focused, accessible path from an idea to a printable part:

- Create primitives and sketches, then turn them into solids.
- Edit models through a recorded, adaptive feature history.
- Join and cut geometry with boolean operations.
- Export finished parts as STL, STEP, or 3MF files.
- Work in a responsive Metal viewport that feels native to Apple platforms.
- Eventually support advanced direct modeling, multiple bodies, and Apple Pencil.

Shapr3D-level functional capability is the long-term north star. Development is staged
so that each milestone proves a complete, dependable part of the architecture before
the next layer of modeling functionality is added.

## Technology

- **Swift 6** for the application, document model, feature history, and kernel API.
- **SwiftUI** for a shared macOS and iPadOS interface.
- **Metal** for real-time mesh rendering and viewport interaction.
- **Swift Concurrency** for serialized geometry and document operations.
- **OpenCASCADE** as the planned initial B-rep geometry engine, isolated behind a
  flat-C bridge so it can be replaced without changing the rest of the application.

All application logic is written in Swift. Geometry engine integration is deliberately
contained in one bridge package; C++ types never enter the Swift application layers.

## Architecture

Caliper keeps the app target intentionally thin. The implementation lives in focused
local Swift packages:

```text
Caliper app
    └── CaliperUI          Shared SwiftUI editor and observable models
            └── CaliperCore    Commands, document state, history, and undo/redo
                    └── CaliperKernel  Engine-independent geometry protocol

CaliperRender             Metal renderer; consumes mesh values only
CaliperTemplates          Parametric development-board templates
CaliperKernelBridge       Isolated OpenCASCADE adapter
```

The central architectural boundary is `GeometryKernel`. Views emit commands rather
than performing geometry directly, the feature graph remains the source of truth, and
the renderer only receives tessellated meshes. This keeps modeling, rendering, and UI
independent of any particular geometry engine.

For the full design, see [Architecture](docs/ARCHITECTURE.md).

## Current status

Caliper is currently working toward the **Phase 1 single-part MVP**. The foundational
package structure, mock geometry kernel, command pipeline, feature graph, undo/redo,
and contract tests are in place. Current work centers on integrating a real geometry
kernel and building the first end-to-end modeling workflows.

See the [current phase](docs/PHASES.md) and [roadmap](docs/ROADMAP.md) for the active
scope and milestone gates.

## Project layout

```text
Caliper/                   Thin multiplatform application shell
Packages/
  CaliperKernel/           GeometryKernel protocol, value types, and MockKernel
  CaliperKernelBridge/     OpenCASCADE facade and Swift kernel adapter
  CaliperCore/             Commands, feature graph, document model, and undo/redo
  CaliperRender/           Metal rendering layer
  CaliperUI/               Shared SwiftUI editor
  CaliperTemplates/        Parametric template library
docs/                      Architecture, requirements, UX, tests, and roadmap
```

## Requirements

- macOS 26 or later
- Xcode with Swift 6.2 support
- Apple silicon or another Metal-capable development Mac

The packages target macOS 26 and iOS 26. iPadOS shipping is planned for a later phase,
but the shared packages are kept platform-independent from the start.

## Build and test

Open `caliper.xcodeproj` in Xcode and run the `caliper` scheme for macOS.

The foundational package tests can also be run from the repository root:

```sh
swift test --package-path Packages/CaliperKernel
swift test --package-path Packages/CaliperCore
```

`KernelConformanceTests` defines the contract every geometry engine must satisfy. The
same suite is intended to validate the mock, OpenCASCADE, and any future kernel.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Current phase](docs/PHASES.md)
- [Roadmap](docs/ROADMAP.md)
- [Software requirements](docs/SRS.md)
- [UI specification](docs/UI_SPEC.md)
- [User journeys](docs/USER_JOURNEYS.md)
- [Test plan](docs/TEST_PLAN.md)

## Contributing

Caliper is evolving alongside its architecture and product documentation. Before
making a change, read [AGENTS.md](AGENTS.md) and [the current phase](docs/PHASES.md).
New capabilities should be documented before implementation, remain within the active
phase, and preserve the geometry-kernel boundary.

## License

No project license has been published yet. All rights are reserved unless a license is
added to this repository.
