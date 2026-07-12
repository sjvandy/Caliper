import SwiftUI
import CaliperKernel
import CaliperUI
// Later, to switch to real geometry, import CaliperKernelBridge and construct OCCTKernel().

/// Single multiplatform app target. Builds and runs identically on macOS and iPadOS.
/// All real work lives in the local Swift packages; this file is just the shell.
@main
struct CaliperApp: App {
    /// The one place the concrete kernel is chosen. Swap MockKernel → OCCTKernel here
    /// (and nowhere else) when the geometry engine is ready. This single line is the
    /// entire cost of the kernel swap, by design.
    @State private var model = EditorModel(kernel: MockKernel())

    var body: some Scene {
        WindowGroup {          // becomes DocumentGroup once CaliperDocument adopts FileDocument
            ModelEditorView()
                .environment(model)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
