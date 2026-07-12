import Foundation
import Testing
@testable import CaliperKernel

/// The conformance suite runs against ANY `GeometryKernel`. Point it at MockKernel
/// today; point it at the OCCT bridge tomorrow — the assertions never change.
/// This is how we guarantee the Parasolid swap is behaviour-preserving.
///
/// Cases trace to docs/TEST_PLAN.md Area K (T-K1…T-K10). Assertions are deliberately
/// kernel-agnostic: they check contract properties (bounds, containment, validity),
/// never engine-specific geometry.
struct KernelConformanceTests {

    private func makeKernel() -> any GeometryKernel { MockKernel() }

    /// A closed 40×20 mm rectangle profile on the base plane.
    private var rectProfile: [Vector3] {
        [Vector3(0, 0, 0), Vector3(40, 0, 0), Vector3(40, 20, 0), Vector3(0, 20, 0)]
    }

    // T-K1
    @Test func boxHasNonEmptyBounds() async throws {
        let k = makeKernel()
        let id = try await k.makeBox(BoxSpec(size: Vector3(10, 20, 30)))
        let b = try await k.bounds(id)
        #expect(b.max.x - b.min.x == 10)
        #expect(b.max.y - b.min.y == 20)
        #expect(b.max.z - b.min.z == 30)
    }

    // T-K2
    @Test func cylinderBoundsMatchRadiusAndHeight() async throws {
        let k = makeKernel()
        let id = try await k.makeCylinder(CylinderSpec(radius: 8, height: 25))
        let b = try await k.bounds(id)
        #expect(b.max.x - b.min.x == 16)
        #expect(b.max.y - b.min.y == 16)
        #expect(b.max.z - b.min.z == 25)
    }

    // T-K3
    @Test func tessellationProducesTriangles() async throws {
        let k = makeKernel()
        let id = try await k.makeBox(BoxSpec(size: Vector3(1, 1, 1)))
        let mesh = try await k.tessellate(id, tolerance: 0.01)
        #expect(mesh.indices.count % 3 == 0)
        #expect(!mesh.positions.isEmpty)
        #expect(mesh.normals.count == mesh.positions.count)
    }

    // T-K4
    @Test func unionOfTwoSolidsSucceeds() async throws {
        let k = makeKernel()
        let a = try await k.makeBox(BoxSpec(size: Vector3(1, 1, 1)))
        let b = try await k.makeBox(BoxSpec(size: Vector3(1, 1, 1), origin: Vector3(0.5, 0, 0)))
        let joined = try await k.boolean(BooleanSpec(kind: .union, target: a, tool: b))
        _ = try await k.bounds(joined) // must not throw
    }

    // T-K5 — subtract yields a valid solid whose bounds stay within the target's.
    @Test func subtractStaysWithinTargetBounds() async throws {
        let k = makeKernel()
        let target = try await k.makeBox(BoxSpec(size: Vector3(40, 40, 20)))
        let tool = try await k.makeCylinder(CylinderSpec(radius: 8, height: 25, origin: Vector3(20, 20, -2)))
        let result = try await k.boolean(BooleanSpec(kind: .subtract, target: target, tool: tool))
        let tb = try await k.bounds(target)
        let rb = try await k.bounds(result)
        #expect(rb.min.x >= tb.min.x && rb.min.y >= tb.min.y && rb.min.z >= tb.min.z)
        #expect(rb.max.x <= tb.max.x && rb.max.y <= tb.max.y && rb.max.z <= tb.max.z)
    }

    // T-K6
    @Test func extrudeClosedProfileSucceedsOpenProfileThrows() async throws {
        let k = makeKernel()
        let solid = try await k.extrude(ExtrudeSpec(profile: rectProfile, distance: 10))
        _ = try await k.bounds(solid) // must not throw
        await #expect(throws: KernelError.self) {
            // Two points cannot form a closed profile.
            _ = try await k.extrude(ExtrudeSpec(profile: [Vector3.zero, Vector3(1, 0, 0)], distance: 10))
        }
    }

    // T-K7
    @Test func transformTranslatesBounds() async throws {
        let k = makeKernel()
        let id = try await k.makeBox(BoxSpec(size: Vector3(2, 2, 2)))
        let before = try await k.bounds(id)
        let moved = try await k.transform(TransformSpec(solid: id, translation: Vector3(5, -3, 7)))
        let after = try await k.bounds(moved)
        #expect(after.min.x == before.min.x + 5)
        #expect(after.min.y == before.min.y - 3)
        #expect(after.min.z == before.min.z + 7)
        #expect(after.max.x == before.max.x + 5)
    }

    // T-K8
    @Test func unknownSolidThrows() async throws {
        let k = makeKernel()
        await #expect(throws: KernelError.self) {
            _ = try await k.bounds(SolidID(999))
        }
    }

    // T-K9
    @Test func exportReturnsNonEmptyDataForEveryFormat() async throws {
        let k = makeKernel()
        let id = try await k.makeBox(BoxSpec(size: Vector3(10, 10, 10)))
        for format in [ExportFormat.stl, .step, .threeMF] {
            let data = try await k.export(id, format: format)
            #expect(!data.isEmpty, "export \(format.rawValue) returned empty data")
        }
    }

    // T-K10
    @Test func resetClearsAllSolids() async throws {
        let k = makeKernel()
        let id = try await k.makeBox(BoxSpec(size: Vector3(1, 1, 1)))
        await k.reset()
        await #expect(throws: KernelError.self) {
            _ = try await k.bounds(id)
        }
    }
}
