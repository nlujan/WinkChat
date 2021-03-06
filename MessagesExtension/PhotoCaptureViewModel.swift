//
//  VideoPreviewHandler.swift
//  WinkChat
//
//  Created by Naim Lujan on 9/12/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import AVFoundation
import RxSwift

class PhotoCaptureViewModel: NSObject {
    
    let captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    fileprivate var cameraOutput = AVCapturePhotoOutput()
    fileprivate var captureDevice: AVCaptureDevice!
    fileprivate let queue = DispatchQueue(label: "AV Session Queue", attributes: [], target: nil)
    fileprivate var authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }
    let imageDataSubject = PublishSubject<Data>()
    
    override init() {
        super.init()
        configurePreviewLayer()
        requestAuthorizationIfNeeded()
        configureSession()
    }
    
    fileprivate func configurePreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer = preview
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }
    
    fileprivate func requestAuthorizationIfNeeded() {
        guard .notDetermined == authorizationStatus else { return }
        queue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            guard granted else { return }
            self.queue.resume()
        }
    }
    
    fileprivate func configureSession() {
        queue.async {
            
            guard .authorized == self.authorizationStatus else { return }
            
            guard let camera: AVCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front) else { return }
            
            defer { self.captureSession.commitConfiguration() }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
            
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: camera)
                self.captureSession.addInput(captureDeviceInput)
                
            } catch {
                print(error.localizedDescription)
                return
            }
            
            guard self.captureSession.canAddOutput(self.cameraOutput) else { return }
            self.captureSession.addOutput(self.cameraOutput)
            
        }
    }
    
    func startSession() {
        queue.async {
            guard self.authorizationStatus == .authorized else { return }
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        queue.async {
            guard self.authorizationStatus == .authorized else { return }
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    func takePhoto() {
        queue.async { [unowned self] in
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                 kCVPixelBufferWidthKey as String: 160,
                                 kCVPixelBufferHeightKey as String: 160,
                                 ]
            settings.previewPhotoFormat = previewFormat
            self.cameraOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension PhotoCaptureViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
            else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        imageDataSubject.onNext(dataImage)
    }
}
