import Foundation
import CaliperKernel

/// The document model: feature graph + the live kernel that evaluates it.
/// The kernel is injected as `any GeometryKernel`, so the whole app is agnostic
/// to whether it's talking to MockKernel, OCCT, or (later) Parasolid.
///
/// Evaluation model (C-3): the graph is the truth; solids are derived. Undo pops
/// the last node and re-evaluates the whole graph from a clean kernel, so replay
/// is deterministic — redo reproduces the identical SolidIDs and bounds (T-C4).
public actor CaliperDocument {
    public private(set) var graph = FeatureGraph()
    private var redoCommands: [Command] = []
    private let kernel: any GeometryKernel

    public init(kernel: any GeometryKernel) { self.kernel = kernel }

    public var canUndo: Bool { !graph.nodes.isEmpty }
    public var canRedo: Bool { !redoCommands.isEmpty }

    /// Apply a command: record it in the graph, then evaluate against the kernel.
    /// A kernel failure never throws out of the document — it flags the feature and
    /// preserves the prior valid state (FR-19). Returns the produced solid, if any.
    @discardableResult
    public func apply(_ command: Command) async -> SolidID? {
        redoCommands.removeAll()
        return await appendAndEvaluate(command)
    }

    /// Removes the last feature and re-derives all solids from the remaining graph.
    public func undo() async {
        guard let removed = graph.removeLast() else { return }
        redoCommands.append(removed.command)
        await reevaluateAll()
    }

    /// Re-applies the most recently undone command.
    public func redo() async {
        guard let command = redoCommands.popLast() else { return }
        await appendAndEvaluate(command)
    }

    /// Bounding box of a produced solid, e.g. for camera framing or inspection.
    /// Views reach geometry only through the document — never the kernel (C-2).
    public func bounds(of solid: SolidID) async throws -> BoundingBox {
        try await kernel.bounds(solid)
    }

    /// Renderer-facing mesh for a produced solid (the only pixel path, C-1).
    public func mesh(for solid: SolidID, tolerance: Double) async throws -> Mesh {
        try await kernel.tessellate(solid, tolerance: tolerance)
    }

    // MARK: - Evaluation

    @discardableResult
    private func appendAndEvaluate(_ command: Command) async -> SolidID? {
        let nodeID = graph.append(command)
        return await evaluate(command, forNode: nodeID)
    }

    /// Replays every node against a freshly reset kernel. Deterministic: the same
    /// graph always yields the same SolidIDs, which is what makes undo/redo and
    /// parametric re-evaluation coherent.
    private func reevaluateAll() async {
        await kernel.reset()
        for node in graph.nodes {
            await evaluate(node.command, forNode: node.id)
        }
    }

    @discardableResult
    private func evaluate(_ command: Command, forNode nodeID: Int) async -> SolidID? {
        do {
            let produced: SolidID
            switch command {
            case .addBox(let s):        produced = try await kernel.makeBox(s)
            case .addCylinder(let s):   produced = try await kernel.makeCylinder(s)
            case .extrudeSketch(let s): produced = try await kernel.extrude(s)
            case .boolean(let s):       produced = try await kernel.boolean(s)
            case .fillet(let s):        produced = try await kernel.fillet(s)
            case .move(let s):          produced = try await kernel.transform(s)
            }
            graph.setProduced(produced, forNode: nodeID)
            return produced
        } catch {
            graph.setError(String(describing: error), forNode: nodeID)
            return nil
        }
    }
}
