import Foundation
import Testing
import CaliperKernel
@testable import CaliperCore

/// Area G — feature graph (docs/TEST_PLAN.md).
struct FeatureGraphTests {

    // T-G2
    @Test func graphSerializationRoundTrips() async throws {
        var graph = FeatureGraph()
        let boxNode = graph.append(.addBox(BoxSpec(size: Vector3(51, 21, 1))))
        graph.setProduced(SolidID(1), forNode: boxNode)
        let cylNode = graph.append(.addCylinder(CylinderSpec(radius: 2.1, height: 3)))
        graph.setError("simulated failure", forNode: cylNode)

        let data = try JSONEncoder().encode(graph)
        let decoded = try JSONDecoder().decode(FeatureGraph.self, from: data)
        #expect(decoded == graph)

        // IDs keep advancing after a round-trip — no collisions with existing nodes.
        var revived = decoded
        let newNode = revived.append(.addBox(BoxSpec(size: Vector3(1, 1, 1))))
        #expect(newNode > cylNode)
    }

    // T-G3 — multi-body is not architecturally blocked (FR-33): the graph may hold
    // several root solids even though Phase 1 UI presents one part.
    @Test func graphPermitsMultipleRootSolids() async throws {
        let doc = CaliperDocument(kernel: MockKernel())
        await doc.apply(.addBox(BoxSpec(size: Vector3(10, 10, 10))))
        await doc.apply(.addBox(BoxSpec(size: Vector3(20, 20, 20), origin: Vector3(50, 0, 0))))
        let graph = await doc.graph
        #expect(graph.producedSolids.count == 2)
    }
}
