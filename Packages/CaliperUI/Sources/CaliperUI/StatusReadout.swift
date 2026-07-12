import SwiftUI
import CaliperCore
import CaliperKernel

/// Compact readout of the feature graph: count, last solid's dimensions, and any
/// evaluation error. This is the visible proof that a toolbar action appended a
/// feature (exit gate G0-4); it grows into the feature-tree panel later.
struct StatusReadout: View {
    @Environment(EditorModel.self) private var model

    var body: some View {
        if !model.nodes.isEmpty {
            VStack(spacing: 4) {
                Text(summary)
                    .font(.body.monospacedDigit())
                if let error = model.lastError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: .capsule)
            .padding(.bottom, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Model status: \(summary)")
        }
    }

    private var summary: String {
        var text = "\(model.nodes.count) feature\(model.nodes.count == 1 ? "" : "s")"
        if let b = model.lastBounds {
            text += " · last solid \(dimension(b.max.x - b.min.x)) × \(dimension(b.max.y - b.min.y)) × \(dimension(b.max.z - b.min.z)) mm"
        }
        return text
    }

    private func dimension(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(1...4)))
    }
}
