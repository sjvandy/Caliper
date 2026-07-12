import SwiftUI
import CaliperCore
import CaliperKernel

/// The shared editor shell. This is where the single-codebase / two-platform
/// strategy pays off: ONE view, platform differences handled by adapters, not forks.
///
/// Discipline reminder: this view emits `Command`s to the document. It must NEVER
/// import CaliperKernelBridge or call a GeometryKernel directly.
public struct ModelEditorView: View {
    @Environment(EditorModel.self) private var model

    public init() {}

    public var body: some View {
        ViewportPlaceholder()
            .overlay(alignment: .top) { toolbar }
            .overlay(alignment: .bottom) { StatusReadout() }
            .ignoresSafeArea()
    }

    private var toolbar: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                Button("Box", systemImage: "cube") {
                    model.send(.addBox(BoxSpec(size: Vector3(20, 20, 20))))
                }
                Button("Cylinder", systemImage: "cylinder") {
                    model.send(.addCylinder(CylinderSpec(radius: 10, height: 20)))
                }
                Divider().frame(height: 20)
                Button("Undo", systemImage: "arrow.uturn.backward") { model.undo() }
                    .disabled(!model.canUndo)
                    .keyboardShortcut("z", modifiers: .command)
                Button("Redo", systemImage: "arrow.uturn.forward") { model.redo() }
                    .disabled(!model.canRedo)
                    .keyboardShortcut("z", modifiers: [.command, .shift])
            }
            .labelStyle(.iconOnly)
            .padding(12)
            .glassEffect(in: .capsule)   // Liquid Glass — see docs/UI_SPEC.md
        }
        .padding(.top, 12)
    }
}

/// Placeholder viewport. Replaced by the Metal-backed view from CaliperRender.
struct ViewportPlaceholder: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.15), .gray.opacity(0.35)],
                           startPoint: .top, endPoint: .bottom)
            ContentUnavailableView("Caliper", systemImage: "scale.3d",
                                   description: Text("Metal viewport goes here."))
        }
    }
}
