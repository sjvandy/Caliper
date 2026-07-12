import CaliperKernel

/// One recorded feature: a Command plus the SolidID it produced when last evaluated.
/// A failed evaluation is flagged here (FR-19) — the node stays in the graph so the
/// user can repair its parameters, and the prior valid solids are untouched.
public struct FeatureNode: Sendable, Codable, Identifiable, Equatable {
    public let id: Int
    public var command: Command
    public var produced: SolidID?
    /// Human-readable failure description from the last evaluation, nil when healthy.
    public var errorMessage: String?

    public init(id: Int, command: Command, produced: SolidID? = nil, errorMessage: String? = nil) {
        self.id = id
        self.command = command
        self.produced = produced
        self.errorMessage = errorMessage
    }

    public var isErrored: Bool { errorMessage != nil }
}
