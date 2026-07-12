import Foundation

/// Opaque, kernel-owned identity for a solid body. Callers never inspect it;
/// they hold it and hand it back to the kernel. This is what lets the underlying
/// engine change without touching a single caller.
public struct SolidID: Hashable, Sendable, Codable {
    public let raw: UInt64
    public init(_ raw: UInt64) { self.raw = raw }
}

public struct Vector3: Hashable, Sendable, Codable {
    public var x, y, z: Double
    public init(_ x: Double, _ y: Double, _ z: Double) { (self.x, self.y, self.z) = (x, y, z) }
    public static let zero = Vector3(0, 0, 0)
}

public struct BoundingBox: Hashable, Sendable, Codable {
    public var min: Vector3
    public var max: Vector3
    public init(min: Vector3, max: Vector3) { self.min = min; self.max = max }
}

/// Renderer-facing triangle mesh. Positions + normals, indexed. The ONLY geometry
/// representation the render layer is allowed to consume.
public struct Mesh: Sendable {
    public var positions: [Vector3]
    public var normals: [Vector3]
    public var indices: [UInt32]
    public init(positions: [Vector3], normals: [Vector3], indices: [UInt32]) {
        self.positions = positions; self.normals = normals; self.indices = indices
    }
    public static let empty = Mesh(positions: [], normals: [], indices: [])
}

// MARK: - Operation specs

public struct BoxSpec: Sendable, Codable, Equatable { public var size: Vector3; public var origin: Vector3
    public init(size: Vector3, origin: Vector3 = .zero) { self.size = size; self.origin = origin } }

public struct CylinderSpec: Sendable, Codable, Equatable { public var radius: Double; public var height: Double; public var origin: Vector3
    public init(radius: Double, height: Double, origin: Vector3 = .zero) { self.radius = radius; self.height = height; self.origin = origin } }

public struct ExtrudeSpec: Sendable, Codable, Equatable {
    /// Closed planar polyline in the sketch plane (millimetres).
    public var profile: [Vector3]
    public var distance: Double
    public init(profile: [Vector3], distance: Double) { self.profile = profile; self.distance = distance }
}

public enum BooleanKind: String, Sendable, Codable { case union, subtract, intersect }
public struct BooleanSpec: Sendable, Codable, Equatable {
    public var kind: BooleanKind; public var target: SolidID; public var tool: SolidID
    public init(kind: BooleanKind, target: SolidID, tool: SolidID) { self.kind = kind; self.target = target; self.tool = tool }
}

public struct FilletSpec: Sendable, Codable, Equatable { public var solid: SolidID; public var radius: Double
    public init(solid: SolidID, radius: Double) { self.solid = solid; self.radius = radius } }

public struct TransformSpec: Sendable, Codable, Equatable {
    public var solid: SolidID
    public var translation: Vector3
    // Extend with rotation/scale as the transform feature grows.
    public init(solid: SolidID, translation: Vector3) { self.solid = solid; self.translation = translation }
}

public enum ExportFormat: String, Sendable, Codable { case stl, step, threeMF }

public enum KernelError: Error, Sendable, Equatable {
    case notImplemented(String)
    case invalidInput(String)
    case operationFailed(String)
    case unknownSolid(SolidID)
}
