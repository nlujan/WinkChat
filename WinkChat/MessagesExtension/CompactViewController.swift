//
//  CompactViewController.swift
//  WinkChat
//
//  Created by Naim Lujan on 4/11/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class CompactViewController: UIViewController {
    
    fileprivate let captureSession = AVCaptureSession()
    fileprivate var previewLayer = AVCaptureVideoPreviewLayer()
    fileprivate var cameraOutput = AVCapturePhotoOutput()
    fileprivate var captureDevice: AVCaptureDevice!
    fileprivate let queue = DispatchQueue(label: "AV Session Queue", attributes: [], target: nil)
    fileprivate var authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
    }
    
    var delegate: SendMessageDelegate?
    @IBOutlet var cameraView: UIView!
    
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViews()
        requestAuthorizationIfNeeded()
        configureSession()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        UIView.animate(withDuration: 0.25) {
//            self.cameraView.alpha = 1.0
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopSession()
        super.viewWillDisappear(animated)
    }
    
    func bindViewModel() {
        
        viewModel
            .gifSubject
            .do(onNext: { gif in
                if gif == nil {
                    print("Face not detected")
                    InfoView.showIn(viewController: self, message: "Face not detected, please try again")
                    self.startSession()
                }
            })
            .filterNil()
            .map { $0.image_url }
            .subscribe(onNext: {url in
                self.delegate?.sendGifMessage(url: url)
                self.startSession()
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        takePhoto()
    }
    
}

extension CompactViewController {
    
    func configureViews() {
        
        guard let preview = AVCaptureVideoPreviewLayer(session: self.captureSession) else { return }
        
        previewLayer = preview
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraView.layer.addSublayer(self.previewLayer)
        previewLayer.frame = self.cameraView.bounds
        
        cameraView.layer.cornerRadius = self.cameraView.frame.size.width/2
        cameraView.clipsToBounds = true
        
        cameraView.layer.borderColor = UIColor.green.cgColor
        cameraView.layer.borderWidth = 5.0
    }
    
    fileprivate func requestAuthorizationIfNeeded() {
        guard .notDetermined == authorizationStatus else { return }
        queue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [unowned self] granted in
            guard granted else { return }
            self.queue.resume()
        }
    }

    fileprivate func configureSession() {
        queue.async {
            
            guard .authorized == self.authorizationStatus else { return }
            
            guard let camera: AVCaptureDevice = AVCaptureDevice.defaultDevice(withDeviceType:
                .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) else { return }
            
            defer { self.captureSession.commitConfiguration() }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = AVCaptureSessionPresetMedium
            
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
    
    fileprivate func takePhoto() {
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
    
    fileprivate func startSession() {
        queue.async {
            guard self.authorizationStatus == .authorized else { return }
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    fileprivate func stopSession() {
        queue.async {
            guard self.authorizationStatus == .authorized else { return }
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
}

extension CompactViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let dataImage = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        stopSession()
        
        let eventsFileURL = URL.cachedFileURL("image.png")
        
        do {
            try dataImage.write(to: eventsFileURL)
            viewModel.imageUrl.onNext(eventsFileURL)
        }
        catch {
            print("Error saving captured photo to disk")
            startSession()
        }
    }
}

protocol SendMessageDelegate {
    func sendGifMessage(url: String)
}
