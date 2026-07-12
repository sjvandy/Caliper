import Foundation

/// The single seam between Caliper and whatever B-rep engine sits underneath
/// (OpenCASCADE today, Parasolid later). Nothing above this protocol may import
/// a concrete kernel. If you find yourself reaching around it, stop: that is the
/// one mistake that makes the Parasolid migration prohibitively expensive.
///
/// Rules of the seam:
///   1. Inputs and outputs are Caliper value types (see KernelTypes.swift), never
///      engine handles. A `SolidID` is an opaque token owned by the kernel.
///   2. Operations are pure with respect to Caliper state: they take IDs + params
///      and return new IDs or a `KernelError`. The kernel owns the geometry store.
///   3. Tessellation is the only path pixels reach the renderer. The renderer never
///      sees B-rep data directly.
public protocol GeometryKernel: Sendable {

    // MARK: Lifecycle
    /// Discards all geometry. Called on new-document / kernel reset.
    func reset() async

    // MARK: Primitives (Milestone 1)
    func makeBox(_ box: BoxSpec) async throws -> SolidID
    func makeCylinder(_ cyl: CylinderSpec) async throws -> SolidID

    // MARK: Sketch → solid (Milestone 1)
    /// Extrude a planar sketch profile into a solid.
    func extrude(_ op: ExtrudeSpec) async throws -> SolidID

    // MARK: Booleans (Milestone 1 — the join/cut pipeline)
    func boolean(_ op: BooleanSpec) async throws -> SolidID

    // MARK: Local ops (Milestone 2+)
    func fillet(_ op: FilletSpec) async throws -> SolidID

    // MARK: Transforms (product vision — parametric transform / move)
    /// A rigid transform recorded as a feature, not a one-shot mutation, so it
    /// participates in the parametric history. See ARCHITECTURE.md "Transform seam".
    func transform(_ op: TransformSpec) async throws -> SolidID

    // MARK: Introspection & output
    /// Triangulated mesh for the renderer at the given chord/deflection tolerance.
    func tessellate(_ id: SolidID, tolerance: Double) async throws -> Mesh
    /// Bounding box in model space, e.g. for framing the camera.
    func bounds(_ id: SolidID) async throws -> BoundingBox

    // MARK: Export (Milestone 1 — STL/STEP/3MF)
    func export(_ id: SolidID, format: ExportFormat) async throws -> Data
}
