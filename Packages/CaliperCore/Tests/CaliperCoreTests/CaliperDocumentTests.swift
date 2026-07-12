import Foundation
import Testing
import CaliperKernel
@testable import CaliperCore

/// Area C — command/document layer (docs/TEST_PLAN.md). Runs on MockKernel; the
/// document is kernel-agnostic, so these hold for any GeometryKernel.
struct CaliperDocumentTests {

    private func makeDocument() -> CaliperDocument {
        CaliperDocument(kernel: MockKernel())
    }

    // T-C1
    @Test func applyAppendsOneNodeAndProducesSolid() async throws {
        let doc = makeDocument()
        let produced = await doc.apply(.addBox(BoxSpec(size: Vector3(20, 20, 20))))
        let graph = await doc.graph
        #expect(graph.nodes.count == 1)
        #expect(produced != nil)
        #expect(graph.nodes[0].produced == produced)
        #expect(!graph.nodes[0].isErrored)
    }

    // T-C2
    @Test func kernelErrorFlagsFeatureAndPreservesPriorState() async throws {
        let doc = makeDocument()
        let first = await doc.apply(.addBox(BoxSpec(size: Vector3(10, 10, 10))))
        let bogus = SolidID(9999)
        let second = await doc.apply(.boolean(BooleanSpec(kind: .subtract,
                                                          target: first!, tool: bogus)))
        #expect(second == nil)
        let graph = await doc.graph
        #expect(graph.nodes.count == 2)
        #expect(graph.nodes[1].isErrored)
        #expect(graph.nodes[1].produced == nil)
        // Prior state intact: first feature still healthy and its solid queryable.
        #expect(!graph.nodes[0].isErrored)
        let b = try await doc.bounds(of: first!)
        #expect(b.max.x - b.min.x == 10)
    }

    // T-C3
    @Test func undoRemovesLastFeatureAndItsSolid() async throws {
        let doc = makeDocument()
        await doc.apply(.addBox(BoxSpec(size: Vector3(10, 10, 10))))
        await doc.apply(.addCylinder(CylinderSpec(radius: 5, height: 8)))
        await doc.undo()
        let graph = await doc.graph
        #expect(graph.nodes.count == 1)
        #expect(graph.producedSolids.count == 1)
        let canRedo = await doc.canRedo
        #expect(canRedo)
    }

    // T-C4
    @Test func redoReproducesIdenticalSolidAndBounds() async throws {
        let doc = makeDocument()
        await doc.apply(.addBox(BoxSpec(size: Vector3(10, 10, 10))))
        let before = await doc.apply(.addCylinder(CylinderSpec(radius: 5, height: 8)))
        let boundsBefore = try await doc.bounds(of: before!)

        await doc.undo()
        await doc.redo()

        let graph = await doc.graph
        #expect(graph.nodes.count == 2)
        let after = graph.nodes[1].produced
        #expect(after == before)
        let boundsAfter = try await doc.bounds(of: after!)
        #expect(boundsAfter == boundsBefore)
    }

    @Test func applyClearsRedoHistory() async throws {
        let doc = makeDocument()
        await doc.apply(.addBox(BoxSpec(size: Vector3(10, 10, 10))))
        await doc.undo()
        await doc.apply(.addBox(BoxSpec(size: Vector3(5, 5, 5))))
        let canRedo = await doc.canRedo
        #expect(!canRedo)
    }
}
