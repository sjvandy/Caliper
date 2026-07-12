import CaliperKernel

/// Placeholder for the Metal render layer. It consumes ONLY `Mesh` values from the
/// kernel — never B-rep data. The real implementation owns the MTKView/CAMetalLayer,
/// camera, and pipeline; shared across macOS and iPadOS with platform input adapters.
public struct RenderScene: Sendable {
    public var meshes: [Mesh]
    public init(meshes: [Mesh] = []) { self.meshes = meshes }
}
