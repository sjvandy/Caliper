import Foundation
import CaliperKernel
import CaliperOCCTFacade

/// GeometryKernel backed by OpenCASCADE via the flat C facade.
///
/// STATUS: skeleton. Every method routes through `CaliperOCCTFacade`, which is
/// currently a stub that returns `false`, so these throw `.notImplemented`. As the
/// facade's real `.mm` implementation lands, fill these in one operation at a time —
/// and each must pass the SAME KernelConformanceTests that MockKernel passes.
public actor OCCTKernel: GeometryKernel {
    public init() {}

    public func reset() async {}

    public func makeBox(_ box: BoxSpec) async throws -> SolidID {
        var out: caliper_solid_t = 0
        let ok = caliper_occt_make_box(box.size.x, box.size.y, box.size.z,
                                       box.origin.x, box.origin.y, box.origin.z, &out)
        guard ok else { throw KernelError.notImplemented("OCCT makeBox — facade stub") }
        return SolidID(out)
    }

    public func makeCylinder(_ cyl: CylinderSpec) async throws -> SolidID { throw KernelError.notImplemented("OCCT makeCylinder") }
    public func extrude(_ op: ExtrudeSpec) async throws -> SolidID { throw KernelError.notImplemented("OCCT extrude") }
    public func boolean(_ op: BooleanSpec) async throws -> SolidID { throw KernelError.notImplemented("OCCT boolean") }
    public func fillet(_ op: FilletSpec) async throws -> SolidID { throw KernelError.notImplemented("OCCT fillet") }
    public func transform(_ op: TransformSpec) async throws -> SolidID { throw KernelError.notImplemented("OCCT transform") }
    public func bounds(_ id: SolidID) async throws -> BoundingBox { throw KernelError.notImplemented("OCCT bounds") }
    public func tessellate(_ id: SolidID, tolerance: Double) async throws -> Mesh { throw KernelError.notImplemented("OCCT tessellate") }
    public func export(_ id: SolidID, format: ExportFormat) async throws -> Data { throw KernelError.notImplemented("OCCT export") }
}
