//
//  BarcodeScannerView.swift
//  GutCheck
//
//  Fixed to remove MealLoggingDestination references
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingMealBuilder = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if viewModel.isAuthorized {
                CameraPreviewView(cameraSession: viewModel.cameraSession)
                    .ignoresSafeArea()
                
                // Scanning overlay
                scanningOverlay
            } else {
                // Camera not authorized view
                VStack(spacing: 20) {
                    Image(systemName: "camera.metering.none")
                        .font(.system(size: 72))
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Text("Camera Access Needed")
                        .font(.title2.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("GutCheck needs camera access to scan barcodes.\nPlease enable camera access in Settings.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Button("Open Settings") {
                        viewModel.openSettings()
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
            
            // Bottom panel
            VStack {
                Spacer()
                
                scanResultsPanel
            }
            
            // Top bar
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
                        
                        Button(action: {
                            viewModel.toggleFlash()
                        }) {
                            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(.trailing, 16)
                    }
                    
                    Text("Scan Barcode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                }
                .padding(.top, 48)
                
                Spacer()
            }
        }
        .alert("Barcode Detected", isPresented: $viewModel.showingAlert) {
            Button("OK") { }
        } message: {
            Text("Barcode value: \(viewModel.scannedBarcode)")
        }
        .onAppear {
            viewModel.checkCameraPermission()
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(item: $viewModel.scannedFoodItem) { foodItem in
            EnhancedFoodItemDetailView(foodItem: foodItem) { updatedItem in
                viewModel.addToMeal(updatedItem)
                showingMealBuilder = true
            }
        }
        .sheet(isPresented: $showingMealBuilder) {
            MealBuilderView()
        }
    }
    
    // Scanning overlay with targeting square
    private var scanningOverlay: some View {
        ZStack {
            // Semi-transparent dark overlay
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .ignoresSafeArea()
                .mask(
                    Rectangle()
                        .overlay(
                            // Cutout for scanning area
                            RoundedRectangle(cornerRadius: 16)
                                .frame(width: 280, height: 180)
                                .blendMode(.destinationOut)
                        )
                )
            
            // Scanning frame
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.accent, lineWidth: 3)
                .frame(width: 280, height: 180)
                .overlay(
                    VStack {
                        Spacer()
                        Text("Align barcode within frame")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, -30)
                )
            
            // Scan animation
            if viewModel.isScanning {
                Rectangle()
                    .fill(ColorTheme.accent.opacity(0.5))
                    .frame(width: 280, height: 2)
                    .offset(y: viewModel.scannerLinePosition)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: viewModel.scannerLinePosition
                    )
                    .onAppear {
                        viewModel.scannerLinePosition = 80
                    }
                    .frame(width: 280, height: 180)
            }
        }
    }
    
    // Bottom panel showing scan results or manual entry option
    private var scanResultsPanel: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Looking up product...")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
                
            } else if viewModel.foundProduct {
                // Product found
                VStack(spacing: 16) {
                    HStack {
                        Text("Product Found")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.clearScannedProduct()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Product image placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ColorTheme.accent.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(ColorTheme.accent)
                            )
                        
                        // Product details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.productName)
                                .font(.headline)
                                .foregroundColor(ColorTheme.primaryText)
                            
                            Text(viewModel.productDescription)
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.secondaryText)
                                .lineLimit(2)
                            
                            Text("Calories: \(viewModel.productCalories) kcal")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    // Add to meal button
                    Button(action: {
                        viewModel.createFoodItemFromScannedProduct()
                    }) {
                        Text("Add to Meal")
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
                
            } else {
                // Default state - scan instructions and manual option
                VStack(spacing: 16) {
                    Text("Scan a food barcode")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Position the barcode within the frame")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Divider()
                    
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // This will be handled by the parent view
                        }
                    }) {
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(ColorTheme.primary)
                            Text("Enter food manually")
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: ColorTheme.shadowColor, radius: 10, y: -5)
            }
        }
    }
}

// Camera preview using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let cameraSession: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// RoundedCorner shape modifier
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
