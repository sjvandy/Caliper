import Foundation

/// A dependency-free stand-in for a real kernel. It fakes geometry (returns unit
/// boxes for tessellation) so the app, the command layer, and the UI can all be
/// built and tested before OCCT is wired in — and so the kernel-conformance test
/// suite has something to run against on any machine.
///
/// This is NOT a real modeler. Anything requiring true B-rep math returns a box
/// or throws `.notImplemented`.
public actor MockKernel: GeometryKernel {
    private var nextID: UInt64 = 1
    private var solids: [SolidID: BoundingBox] = [:]

    public init() {}

    private func mint(_ bounds: BoundingBox) -> SolidID {
        let id = SolidID(nextID); nextID += 1; solids[id] = bounds; return id
    }

    public func reset() async { solids.removeAll(); nextID = 1 }

    public func makeBox(_ box: BoxSpec) async throws -> SolidID {
        mint(BoundingBox(min: box.origin,
                         max: Vector3(box.origin.x + box.size.x,
                                      box.origin.y + box.size.y,
                                      box.origin.z + box.size.z)))
    }

    public func makeCylinder(_ cyl: CylinderSpec) async throws -> SolidID {
        mint(BoundingBox(min: Vector3(cyl.origin.x - cyl.radius, cyl.origin.y - cyl.radius, cyl.origin.z),
                         max: Vector3(cyl.origin.x + cyl.radius, cyl.origin.y + cyl.radius, cyl.origin.z + cyl.height)))
    }

    public func extrude(_ op: ExtrudeSpec) async throws -> SolidID {
        guard op.profile.count >= 3 else { throw KernelError.invalidInput("profile needs ≥3 points") }
        return mint(BoundingBox(min: .zero, max: Vector3(1, 1, op.distance)))
    }

    public func boolean(_ op: BooleanSpec) async throws -> SolidID {
        guard let t = solids[op.target] else { throw KernelError.unknownSolid(op.target) }
        guard solids[op.tool] != nil else { throw KernelError.unknownSolid(op.tool) }
        return mint(t) // fake: keep target bounds
    }

    public func fillet(_ op: FilletSpec) async throws -> SolidID {
        guard let b = solids[op.solid] else { throw KernelError.unknownSolid(op.solid) }
        return mint(b)
    }

    public func transform(_ op: TransformSpec) async throws -> SolidID {
        guard let b = solids[op.solid] else { throw KernelError.unknownSolid(op.solid) }
        let t = op.translation
        return mint(BoundingBox(min: Vector3(b.min.x + t.x, b.min.y + t.y, b.min.z + t.z),
                                max: Vector3(b.max.x + t.x, b.max.y + t.y, b.max.z + t.z)))
    }

    public func bounds(_ id: SolidID) async throws -> BoundingBox {
        guard let b = solids[id] else { throw KernelError.unknownSolid(id) }; return b
    }

    public func tessellate(_ id: SolidID, tolerance: Double) async throws -> Mesh {
        guard let b = solids[id] else { throw KernelError.unknownSolid(id) }
        return Self.boxMesh(min: b.min, max: b.max)
    }

    public func export(_ id: SolidID, format: ExportFormat) async throws -> Data {
        guard solids[id] != nil else { throw KernelError.unknownSolid(id) }
        return Data("MOCK-\(format.rawValue)".utf8)
    }

    /// 12-triangle axis-aligned box, flat normals — enough for the renderer to draw something.
    static func boxMesh(min lo: Vector3, max hi: Vector3) -> Mesh {
        let p = [Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z),
                 Vector3(hi.x, hi.y, lo.z), Vector3(lo.x, hi.y, lo.z),
                 Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z),
                 Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)]
        let idx: [UInt32] = [0,1,2, 0,2,3, 4,6,5, 4,7,6, 0,4,5, 0,5,1,
                             1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0]
        return Mesh(positions: p, normals: Array(repeating: Vector3(0,0,1), count: p.count), indices: idx)
    }
}
