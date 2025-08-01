//
//  LiDARScannerView.swift
//  GutCheck
//
//  Fixed to use correct component names
//

import SwiftUI
import ARKit
import RealityKit
import CoreML

struct LiDARScannerView: View {
    @StateObject private var viewModel = LiDARScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingMealBuilder = false
    
    var body: some View {
        ZStack {
            if let errorMessage = viewModel.lidarErrorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 72))
                        .foregroundColor(ColorTheme.secondaryText)
                    Text("LiDAR Error")
                        .font(.title2.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                    Button("Try Another Method") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                    .padding(.top, 8)
                }
                .padding()
                .background(ColorTheme.background.ignoresSafeArea())
            } else if viewModel.isDeviceSupported {
                ARViewContainer(session: viewModel.arSession, delegate: viewModel)
                    .ignoresSafeArea()
                scanningOverlay(viewModel: viewModel)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.metering.none")
                        .font(.system(size: 72))
                        .foregroundColor(ColorTheme.secondaryText)
                    Text("LiDAR Not Available")
                        .font(.title2.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    Text("This feature requires an iPhone with LiDAR sensor (iPhone 12 Pro/Pro Max or newer).")
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                    Button("Try Another Method") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                    .padding(.top, 8)
                }
                .padding()
                .background(ColorTheme.background.ignoresSafeArea())
            }
            VStack {
                Spacer()
                if viewModel.scanStage == .initial {
                    initialInstructionsPanel(viewModel: viewModel)
                } else if viewModel.scanStage == .scanning {
                    scanningControlsPanel(viewModel: viewModel)
                } else if viewModel.scanStage == .processing {
                    processingPanel(viewModel: viewModel)
                } else if viewModel.scanStage == .results {
                    resultsPanel(viewModel: viewModel)
                }
            }
            VStack {
                ZStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.leading, 16)
                        Spacer()
                    }
                    Text(viewModel.scanStage.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                }
                .padding(.top, 48)
                Spacer()
            }
        }
        .onAppear {
            viewModel.checkDeviceCapabilities()
            viewModel.startARSession()
        }
        .onDisappear {
            viewModel.stopARSession()
        }
    }
    
    // Scanning overlay with targeting guides
    @MainActor
    private func scanningOverlay(viewModel: LiDARScannerViewModel) -> some View {
        ZStack {
            if viewModel.scanStage == .scanning {
                // Targeting box
                Rectangle()
                    .stroke(ColorTheme.accent, lineWidth: 3)
                    .frame(width: 200, height: 200)
                    .overlay(
                        VStack {
                            Spacer()
                            Text("Position food in this area")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                        }
                        .padding(.bottom, -30)
                    )
                // Distance guidance
                VStack {
                    Spacer()
                        .frame(height: 240)
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f m", viewModel.currentDistance))
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(viewModel.distanceGuidance)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    // Initial instructions panel
    @MainActor
    private func initialInstructionsPanel(viewModel: LiDARScannerViewModel) -> some View {
        VStack(spacing: 16) {
            Text("LiDAR Portion Scanner")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            Text("Use your iPhone's LiDAR scanner to estimate food portions. Follow these steps:")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("1")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(ColorTheme.primary))
                    Text("Point camera at your food from about 30-40cm away")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                }
                HStack(alignment: .top, spacing: 12) {
                    Text("2")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(ColorTheme.primary))
                    Text("Position the food within the targeting box")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                }
                HStack(alignment: .top, spacing: 12) {
                    Text("3")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(ColorTheme.primary))
                    Text("Hold steady and tap the camera button to scan")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorTheme.surface)
            )
            Button(action: {
                viewModel.startScanning()
            }) {
                Text("Start Scanning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accent)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
    }
    // Scanning controls panel
    @MainActor
    private func scanningControlsPanel(viewModel: LiDARScannerViewModel) -> some View {
        VStack(spacing: 16) {
            Text("Position camera 30-40cm from food")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
            Button(action: {
                viewModel.captureFrame()
            }) {
                HStack {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 32))
                    Text("Capture")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTheme.accent)
                )
            }
            Button(action: {
                viewModel.resetScan()
            }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
    }
    // Processing panel
    @MainActor
    private func processingPanel(viewModel: LiDARScannerViewModel) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Analyzing food...")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            Text("Using AI to identify food type and estimate portion size")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
    }
    // Results panel
    @MainActor
    private func resultsPanel(viewModel: LiDARScannerViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Analysis Results")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                Spacer()
                Button(action: {
                    viewModel.resetScan()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(ColorTheme.primary)
                }
            }
            HStack(alignment: .top, spacing: 16) {
                // Food image (captured)
                if let foodImage = viewModel.capturedImage {
                    Image(uiImage: foodImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorTheme.accent.opacity(0.2))
                        .frame(width: 80, height: 80)
                }
                // Food details
                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted Food:")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    ForEach(viewModel.foodPredictions, id: \.self) { prediction in
                        Button(action: {
                            viewModel.detectedFoodName = prediction
                        }) {
                            Text(prediction)
                                .font(.headline)
                                .foregroundColor(prediction == viewModel.detectedFoodName ? ColorTheme.accent : ColorTheme.primaryText)
                                .padding(.vertical, 2)
                        }
                    }
                    Text("Est. volume: \(String(format: "%.0f", viewModel.estimatedVolume)) ml")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    Text("Est. weight: \(String(format: "%.0f", viewModel.estimatedWeight)) g")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
            }
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.createFoodItemFromScan()
                    }
                }) {
                    Text("Add to Meal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.accent)
                        .cornerRadius(12)
                }
                Button(action: {
                    viewModel.resetScan()
                }) {
                    Text("Scan Again")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
    }

// MARK: - ARViewContainer

struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    let delegate: ARSessionDelegate
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = session
        
        // Configure ARView
        arView.automaticallyConfigureSession = false
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // No updates needed here as the session is managed externally
    }
}

// Note: RoundedCorner and cornerRadius extension are already defined elsewhere in the project
