import CaliperKernel

/// The parametric history, as data. Each node is a recorded Command plus the
/// SolidID(s) it produced. Editing an upstream node re-evaluates downstream —
/// this is the "adaptive parametric history" and the source of truth for the model.
/// Multi-body lives here naturally: the graph may own more than one root SolidID.
public struct FeatureGraph: Sendable, Codable, Equatable {
    public private(set) var nodes: [FeatureNode] = []
    private var nextID = 0

    public init() {}

    /// Records a command as a new feature node. Returns the node's id.
    public mutating func append(_ command: Command) -> Int {
        let id = nextID; nextID += 1
        nodes.append(FeatureNode(id: id, command: command))
        return id
    }

    /// Stores the solid a node's evaluation produced and clears any prior error.
    public mutating func setProduced(_ solid: SolidID?, forNode nodeID: Int) {
        guard let i = nodes.firstIndex(where: { $0.id == nodeID }) else { return }
        nodes[i].produced = solid
        nodes[i].errorMessage = nil
    }

    /// Flags a node whose evaluation failed (FR-19). The node keeps its command so
    /// the user can repair parameters; it produces no solid until it re-evaluates.
    public mutating func setError(_ message: String, forNode nodeID: Int) {
        guard let i = nodes.firstIndex(where: { $0.id == nodeID }) else { return }
        nodes[i].errorMessage = message
        nodes[i].produced = nil
    }

    /// Removes and returns the most recent feature (undo support).
    public mutating func removeLast() -> FeatureNode? {
        nodes.popLast()
    }

    /// Solids currently produced by healthy nodes, in feature order. Render and
    /// export derive from this (C-3). Multiple roots are permitted (FR-33).
    public var producedSolids: [SolidID] {
        nodes.compactMap(\.produced)
    }
}
