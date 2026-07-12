import CaliperKernel

/// The intent/command layer. VIEWS EMIT COMMANDS; THEY NEVER CALL THE KERNEL.
/// Every user edit is a value here. This is what makes undo/redo, the parametric
/// history, and eventual scripting/automation fall out for free.
public enum Command: Sendable, Codable, Equatable {
    case addBox(BoxSpec)
    case addCylinder(CylinderSpec)
    case extrudeSketch(ExtrudeSpec)
    case boolean(BooleanSpec)     // the join/cut pipeline
    case fillet(FilletSpec)
    case move(TransformSpec)      // parametric transform / move — part of the product vision
}
