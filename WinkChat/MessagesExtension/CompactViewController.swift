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
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }
    
    var delegate: SendMessageDelegate?
    @IBOutlet var cameraView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var cameraButton: UIButton!
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.isHidden = true
        
        if RxReachability.shared.startMonitor("giphy.com") == false {
            print("Reachability failed!")
        }
        
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
            .map { $0.image_url }
            .subscribe(onNext: {url in
                self.updateActivityIndicator(isRunning: false)
                self.delegate?.sendGifMessage(url: url)
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        
        viewModel
            .errorSubject
            .subscribe(onNext: {error in
                self.updateActivityIndicator(isRunning: false)
                InfoView.showIn(viewController: self, message: "No face detected")
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        cameraButton.rx.tap
            .subscribe(onNext: { _ in
                self.updateActivityIndicator(isRunning: true)
                self.takePhoto()
            })
            .disposed(by: disposeBag)
        
    }
    
    func updateActivityIndicator(isRunning: Bool) {
        
        activityIndicator.isHidden = !isRunning
        if isRunning {
            self.activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
        
    }
    
    func notifyUpdatedImageUrl(imageUrl: URL) {
        
        guard RxReachability.shared.isOnline() else {
            InfoView.showIn(viewController: self, message: "No internet connection found, please reconnect and try again")
            startSession()
            return
        }
        viewModel.imageUrlSubject.onNext(imageUrl)
    }
    
}

extension CompactViewController {
    
    func configureViews() {
        
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        
        previewLayer = preview
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame = cameraView.bounds
        
        cameraView.layer.cornerRadius = cameraView.frame.size.width/2
        cameraView.clipsToBounds = true
        
        cameraView.layer.borderColor = UIColor.green.cgColor
        cameraView.layer.borderWidth = 8.0
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
            
            guard let camera: AVCaptureDevice = AVCaptureDevice
                .default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) else { return }
            
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
            notifyUpdatedImageUrl(imageUrl: eventsFileURL)
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
