//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Naim Lujan on 4/9/17.
//  Copyright © 2017 Naim Lujan. All rights reserved.
//

import UIKit
import Messages
import AVFoundation
import RxSwift
import RxCocoa

class MessagesViewController: MSMessagesAppViewController {
    
    fileprivate let captureSession = AVCaptureSession()
    fileprivate var previewLayer = AVCaptureVideoPreviewLayer()
    fileprivate var cameraOutput = AVCapturePhotoOutput()
    fileprivate var captureDevice: AVCaptureDevice!
    fileprivate let queue = DispatchQueue(label: "AV Session Queue", attributes: [], target: nil)
    fileprivate var authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }
    fileprivate let disposeBag = DisposeBag()
    fileprivate let viewModel = ViewModel()
    fileprivate let gifImages = Variable<[Gif]>([])
    
    @IBOutlet var cameraView: SpinningView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var mainCameraControlsView: UIView!
    
    @IBOutlet var activityContainer: UIView!
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        
        super.willBecomeActive(with: conversation)
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
}

extension MessagesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if RxReachability.shared.startMonitor("giphy.com") == false {
            print("Reachability failed!")
        }
        
        configureViews()
        
        collectionView.setCollectionViewLayout(GifCollectionViewLayout(), animated: false)
        if let layout = collectionView?.collectionViewLayout as? GifCollectionViewLayout {
            layout.delegate = self
        }
        
        
        
        bindCollectionView()
        
        
        
        requestAuthorizationIfNeeded()
        configureSession()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
        
        mainCameraControlsView.alpha = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 2.0) {
            self.mainCameraControlsView.alpha = 1.0
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopSession()
        super.viewWillDisappear(animated)
    }
    
    func bindViewModel() {
        
        viewModel
            .randomGifSubject
            .map { $0.image_url }
            .subscribe(onNext: {url in
                self.updateActivityIndicator(isRunning: false)
                self.addGifToInputField(url: url)
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        viewModel
            .searchGifsSubject
            .subscribe(onNext: {gifs in
                self.gifImages.value = gifs
                self.updateActivityIndicator(isRunning: false)
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        viewModel
            .errorSubject
            .subscribe(onNext: { error in
                self.updateActivityIndicator(isRunning: false)
                
                switch error as! APIError {
                    case .NoFaceDetected:
                        InfoView.showIn(viewController: self, message: "No face detected, please try again")
                    case .NoGifRecieved:
                        InfoView.showIn(viewController: self, message: "Unable to retreive Gif, please try again")
                }
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
        
        if isRunning {
            cameraView.animating = true
        } else {
            cameraView.animating = false
        }
    }
    
    func notifyViewModelOfImageUrl(imageUrl: URL) {
        
        guard RxReachability.shared.isOnline() else {
            updateActivityIndicator(isRunning: false)
            InfoView.showIn(viewController: self, message: "No internet connection found, please reconnect and try again")
            startSession()
            return
        }
        if presentationStyle == .compact {
            viewModel.randomUrlSubject.onNext(imageUrl)
            viewModel.searchUrlSubject.onNext(imageUrl)
        } else {
            viewModel.searchUrlSubject.onNext(imageUrl)
        }
    }
    
    func addGifToInputField(url: String) {
        
        if presentationStyle == .expanded {
            requestPresentationStyle(.compact)
        }
        
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        
        guard let bundleURL = URL(string: url) else {
            print("Error: This image named \"\(url)\" does not exist")
            return
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("Error: Cannot turn image named \"\(url)\" into NSData")
            return
        }
        
        let eventsFileURL = URL.cachedFileURL("test.gif")
        try? imageData.write(to: eventsFileURL)
        
        conversation.insertAttachment(eventsFileURL, withAlternateFilename: "test.gif") { error in
            if let error = error {
                print(error)
            }
        }
        
        collectionView.isUserInteractionEnabled = true
    }
    
    func bindCollectionView() {
        
        gifImages.asObservable().bindTo(collectionView.rx.items(cellIdentifier: "gifCell", cellType: GifCell.self))
        { row, data, cell in
            cell.backgroundColor = UIColor().getRandom()
            cell.gif.sd_setImage(with: URL(string: data.image_url))
            }.addDisposableTo(disposeBag)
        
        collectionView.rx
            .itemSelected
            .subscribe(onNext: { indexPath in
                self.collectionView.isUserInteractionEnabled = false
                
                let gif = self.gifImages.value[indexPath.row]
                
                guard let cell = self.collectionView.cellForItem(at: indexPath) else {
                    return
                }
                
                UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5, options: [],
                   animations: { cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) },
                   completion: { finished in
                        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 5, options: .curveEaseInOut,
                           animations: { cell.transform = CGAffineTransform(scaleX: 1, y: 1) },
                           completion: { finished in
                                self.addGifToInputField(url: gif.image_url)
                        }) }
                )
                
            })
            .disposed(by: disposeBag)
    }
}

extension MessagesViewController {
    
    func configureViews() {
        
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        
        previewLayer = preview
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame = cameraView.bounds.insetBy(dx: cameraView.lineWidth, dy: cameraView.lineWidth)
        
        cameraView.layer.cornerRadius = cameraView.frame.size.width/2
        previewLayer.cornerRadius = previewLayer.frame.size.width/2
        
//        cameraView.layer.borderColor = UIColor.green.cgColor
//        cameraView.layer.borderWidth = 8.0
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
            
            guard let camera: AVCaptureDevice = AVCaptureDevice.DiscoverySession(__deviceTypes: [.builtInWideAngleCamera],
                 mediaType: AVMediaType.video, position: .front).devices.first else { return }
            
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
            let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first!
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

// MARK: - AVCapturePhotoCaptureDelegate

extension MessagesViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let dataImage = photo.fileDataRepresentation() else {
            print("Error capturing photo: \(String(describing: error))")
            return
        }
        stopSession()
        
        let eventsFileURL = URL.cachedFileURL("image.png")
        
        do {
            try dataImage.write(to: eventsFileURL)
            notifyViewModelOfImageUrl(imageUrl: eventsFileURL)
        }
        catch {
            print("Error saving captured photo to disk")
            startSession()
        }
    }
}

extension MessagesViewController : GifCollectionViewLayoutDelegate {
    func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let gif = gifImages.value[indexPath.item]
        let boundingRect =  CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect  = AVMakeRect(aspectRatio: CGSize.init(width: Int(gif.width)!, height: Int(gif.height)!), insideRect: boundingRect)
        return rect.size.height
    }
}
