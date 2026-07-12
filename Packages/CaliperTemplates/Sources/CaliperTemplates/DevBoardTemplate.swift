import CaliperKernel
import CaliperCore

/// Parametric dev-board template library. Templates emit Commands, so they flow
/// through the exact same pipeline as manual edits — no special-casing.
public struct DevBoardTemplate: Sendable {
    public let name: String
    public let commands: [Command]

    /// Raspberry Pi Pico: 51 × 21 × 1 mm, 47.0 × 11.4 mm four-hole mounting pattern.
    public static let raspberryPiPico = DevBoardTemplate(
        name: "Raspberry Pi Pico",
        commands: [.addBox(BoxSpec(size: Vector3(51, 21, 1)))]
        // Mounting holes added as cylinder-subtract booleans once the pipeline is live.
    )
}
