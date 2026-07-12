import Observation
import os
import CaliperCore
import CaliperKernel

/// Observable UI-facing model. Bridges SwiftUI to the actor-isolated document.
/// The view calls `send(_:)`; the model forwards to the document; the kernel is
/// entirely hidden behind CaliperCore. Views therefore stay kernel-agnostic.
///
/// Commands are applied strictly in the order they were sent (each queued task
/// awaits its predecessor), so rapid tool clicks cannot interleave.
@Observable
@MainActor
public final class EditorModel {
    private let document: CaliperDocument
    private var pending: Task<Void, Never>?
    private let log = Logger(subsystem: "app.caliper", category: "editor")

    /// Snapshot of the feature graph after the latest evaluation. Views render this.
    public private(set) var nodes: [FeatureNode] = []
    public private(set) var canUndo = false
    public private(set) var canRedo = false
    /// Bounds of the most recently produced solid — the "mock bounds" visibility
    /// required by exit gate G0-4, and later the camera-framing input.
    public private(set) var lastBounds: BoundingBox?
    /// Message of the most recent errored feature, nil when the graph is healthy.
    public private(set) var lastError: String?

    public init(kernel: any GeometryKernel) {
        self.document = CaliperDocument(kernel: kernel)
    }

    public func send(_ command: Command) {
        enqueue { await $0.apply(command) }
    }

    public func undo() {
        enqueue { await $0.undo() }
    }

    public func redo() {
        enqueue { await $0.redo() }
    }

    private func enqueue(_ work: @escaping @MainActor (CaliperDocument) async -> Void) {
        let prior = pending
        pending = Task {
            await prior?.value
            await work(document)
            await refresh()
        }
    }

    private func refresh() async {
        let graph = await document.graph
        nodes = graph.nodes
        canUndo = await document.canUndo
        canRedo = await document.canRedo
        lastError = graph.nodes.last?.errorMessage
        if let last = graph.producedSolids.last {
            lastBounds = try? await document.bounds(of: last)
        } else {
            lastBounds = nil
        }
        log.info("feature graph: \(graph.nodes.count) node(s), \(graph.producedSolids.count) solid(s), last bounds: \(String(describing: self.lastBounds))")
    }
}
