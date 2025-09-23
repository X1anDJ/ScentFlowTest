//
//  ScannerViewModel.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/22/25.
//


//
//  ScannerViewModel.swift
//  MeshGradient
//

import SwiftUI
import Combine
import AVFoundation
import UIKit

final class ScannerViewModel: NSObject, ObservableObject {
    // Observed UI state
    @Published var authorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var lastScannedCode: String?
    @Published var showBanner: Bool = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String?
    @Published var isTorchOn: Bool = false

    // Capture
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var metadataOutput = AVCaptureMetadataOutput()
    private var isConfigured = false
    private var canEmitNext = true   // throttle duplicates

    // Request permission, then configure once authorized
    @MainActor
    func requestPermissionAndConfigure() async {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        if current == .notDetermined {
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                AVCaptureDevice.requestAccess(for: .video) { continuation.resume(returning: $0) }
            }
            authorization = granted ? .authorized : .denied
        } else {
            authorization = current
        }

        if authorization == .authorized {
            configureIfNeeded()
        }
    }

    func startIfNeeded() {
        guard authorization == .authorized else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Input
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.fail("Unable to access the back camera.")
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            // Metadata output (barcodes + QR)
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                self.metadataOutput.metadataObjectTypes = supportedSymbologies()
            } else {
                self.fail("Unable to add metadata output.")
                self.session.commitConfiguration()
                return
            }

            self.session.commitConfiguration()
        }
    }

    func supportedSymbologies() -> [AVMetadataObject.ObjectType] {
        var types: [AVMetadataObject.ObjectType] = [
            .qr, .aztec, .dataMatrix, .pdf417,
            .ean8, .ean13, .upce,
            .code39, .code39Mod43, .code93, .code128,
            .itf14, .interleaved2of5
        ]
        if #available(iOS 15.4, *) {
            // Placeholder for newer types if added later
        }
        return types
    }

    
    func toggleTorch() {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                if device.isTorchActive {
                    device.torchMode = .off
                    DispatchQueue.main.async { self.isTorchOn = false }
                } else {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                    DispatchQueue.main.async { self.isTorchOn = true }
                }
                device.unlockForConfiguration()
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Torch is unavailable."
                    self.showErrorAlert = true
                }
            }
        }
    }

    private func fail(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showErrorAlert = true
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension ScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard canEmitNext else { return }

        if let readable = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = readable.stringValue {
            lastScannedCode = value
            flashBanner()
            haptic()
            canEmitNext = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.canEmitNext = true }
        }
    }

    private func flashBanner() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.showBanner = false
            }
        }
    }

    private func haptic() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}
