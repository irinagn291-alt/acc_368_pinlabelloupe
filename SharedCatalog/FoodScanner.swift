import AVFoundation
import SwiftUI
import VisionKit

struct FoodScanner: View {
    let onCode: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var cameraReady = false
    @State private var issue: String?
    @State private var settingsAvailable = false

    var body: some View {
        NavigationStack {
            Group {
                if let issue {
                    ContentUnavailableView {
                        Label("Scanner unavailable", systemImage: "barcode.viewfinder")
                    } description: { Text(issue) } actions: {
                        if settingsAvailable {
                            Button("Open Settings") { openURL(URL(string: UIApplication.openSettingsURLString)!) }
                        }
                        Button("Back to search") { dismiss() }
                    }
                } else if cameraReady {
                    ScannerCamera(onCode: onCode, onFailure: { issue = "Enter the digits printed under the barcode in the search field." })
                        .safeAreaInset(edge: .bottom) {
                            Text("Point the camera at the product barcode")
                                .font(.callout.bold()).padding().frame(maxWidth: .infinity).background(.regularMaterial)
                        }
                } else { ProgressView() }
            }
            .navigationTitle("Barcode scanner").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .task {
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotLaunch.enabled { dismiss(); return }
                #endif
                guard DataScannerViewController.isSupported else {
                    issue = "On this device, enter the digits printed under the barcode in the search field."
                    return
                }
                let state = AVCaptureDevice.authorizationStatus(for: .video)
                let granted: Bool
                if state == .notDetermined { granted = await AVCaptureDevice.requestAccess(for: .video) }
                else { granted = state == .authorized }
                guard granted else {
                    settingsAvailable = AVCaptureDevice.authorizationStatus(for: .video) == .denied
                    issue = "Camera access is unavailable. You can type the barcode in the search field."
                    return
                }
                if DataScannerViewController.isAvailable { cameraReady = true }
                else { issue = "The camera is busy. Try again later or enter the barcode by hand." }
            }
        }
    }
}

private struct ScannerCamera: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onFailure: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode, onFailure: onFailure) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let camera = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .upce, .itf14, .qr])],
                                               qualityLevel: .balanced, recognizesMultipleItems: false,
                                               isGuidanceEnabled: true, isHighlightingEnabled: true)
        camera.delegate = context.coordinator
        do { try camera.startScanning() }
        catch { DispatchQueue.main.async { onFailure() } }
        return camera
    }
    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        let onFailure: () -> Void
        var finished = false
        init(onCode: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
            self.onCode = onCode
            self.onFailure = onFailure
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                guard !finished, case .barcode(let barcode) = item, let text = barcode.payloadStringValue,
                      let code = FoodCatalog.barcode(text) else { continue }
                finished = true
                dataScanner.stopScanning()
                onCode(code)
                break
            }
        }
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            if !finished { onFailure() }
        }
    }
}
