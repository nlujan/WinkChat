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
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
    }
    fileprivate let disposeBag = DisposeBag()
    fileprivate let viewModel = ViewModel()
    fileprivate let gifs = Variable<[Gif]>([])
    fileprivate var currentOrientation: UIInterfaceOrientation = .portrait
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var placeHolderView: UITextView!
    @IBOutlet var bottomViewContainer: UIView!
    @IBOutlet var bottomContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var selfieImageContainer: UIView!
    @IBOutlet var cameraView: SpinningView!
    @IBOutlet var cameraButton: UIButton!
    
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
        
        layoutInfoView()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
    }
}

// MARK: - UIViewController Overload Methods

extension MessagesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIScreen.main.bounds.height > 667 {
            bottomContainerHeightConstraint.constant = 227
            bottomViewContainer.layoutIfNeeded()
        }
        
        if RxReachability.shared.startMonitor(Constants.Giphy.Url) == false {
            print("Reachability failed!")
        }
        
        if let layout = collectionView?.collectionViewLayout as? GifCollectionViewLayout {
            layout.delegate = self
        }
        
        configurePreviewLayer()
        requestAuthorizationIfNeeded()
        configureSession()
        previewLayer.setOrientation(orientation: UIScreen.main.orientation)
        layoutCollectionView()
        bindCollectionView()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopSession()
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        
        if UIScreen.main.orientation != currentOrientation {
            previewLayer.setOrientation(orientation: UIScreen.main.orientation)
            layoutSelfieView()
            layoutInfoView()
            layoutCollectionView()
            currentOrientation = UIScreen.main.orientation
        }
    }
}

// MARK: - ViewModel Binding and Interaction

extension MessagesViewController {
    
    fileprivate func bindViewModel() {
        
        viewModel
            .randomGifSubject
            .map { $0.image_url }
            .subscribe(onNext: { [unowned self] url in
                self.addGifToInputField(url: url)
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        viewModel
            .searchGifsSubject
            .subscribe(onNext: { [unowned self] gifs in
                self.gifs.value = gifs
                self.layoutCollectionView()
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        viewModel
            .errorSubject
            .subscribe(onNext: { [unowned self] error in
                switch error as! APIError {
                    case .NoFaceDetected:
                        InfoView.showIn(viewController: self, message: Constants.ErrorMessage.NoFaceDetected)
                    case .NoGifRecieved:
                        InfoView.showIn(viewController: self, message: Constants.ErrorMessage.NetworkIssue)
                }
                self.startSession()
            })
            .disposed(by: disposeBag)
        
        cameraButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                print("hello")
                self.takePhoto()
            })
            .disposed(by: disposeBag)
        
        Observable.from([
            viewModel.randomUrlSubject.map { _ in true },
            viewModel.searchUrlSubject.map { _ in true },
            viewModel.searchGifsSubject.map { _ in false }.filter { [unowned self] _ in
                self.presentationStyle == .expanded
            },
            viewModel.errorSubject.map { _ in false }
            ]).merge()
            .asDriver(onErrorJustReturn: false)
            .asObservable()
            .subscribe(onNext: { [unowned self] isRunning in
                self.cameraView.animating = isRunning
            })
            .disposed(by: disposeBag)
        
        Observable.from([
            cameraButton.rx.tap.map { _ in false },
            viewModel.searchGifsSubject.map { _ in true }.filter { [unowned self] _ in
                self.presentationStyle == .expanded
            },
            viewModel.errorSubject.map { _ in true }
            ]).merge()
            .asDriver(onErrorJustReturn: true)
            .drive(cameraButton.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)
    }
    
    fileprivate func notifyViewModelOf(imageUrl: URL) {
        
        guard RxReachability.shared.isOnline() else {
            InfoView.showIn(viewController: self, message: Constants.ErrorMessage.NetworkIssue)
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
}

extension MessagesViewController {
    
    fileprivate func addGifToInputField(url: String, closure: (() -> Void)? = nil) {
        
        if presentationStyle == .expanded {
            requestPresentationStyle(.compact)
        }
        
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        
        guard let bundleURL = URL(string: url) else {
            viewModel.errorSubject.onNext(APIError.NoGifRecieved)
            print("Error: This image named \"\(url)\" does not exist")
            return
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            viewModel.errorSubject.onNext(APIError.NoGifRecieved)
            print("Error: Cannot turn image named \"\(url)\" into NSData")
            return
        }
        
        let gifFileURL = URL.cachedFileURL(Constants.GifFilename)
        
        do {
            try imageData.write(to: gifFileURL)
        } catch {
            print("Error saving gif to disk")
        }
        
        self.cameraView.animating = false
        self.cameraButton.isUserInteractionEnabled = true
        
        conversation.insertAttachment(gifFileURL, withAlternateFilename: nil) { [unowned self] error in
            if let error = error {
                self.viewModel.errorSubject.onNext(APIError.NoGifRecieved)
                print(error)
            }
            closure?()
        }
    }
}

// MARK: - AVCaptureVideoPreviewLayer configuration and layout

extension MessagesViewController {

    fileprivate func configurePreviewLayer() {
        
        guard let preview = AVCaptureVideoPreviewLayer(session: self.captureSession) else { return }
        
        previewLayer = preview
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame = cameraView.bounds.insetBy(dx: cameraView.lineWidth, dy: cameraView.lineWidth)
        cameraView.layer.cornerRadius = cameraView.frame.size.width/2
        previewLayer.cornerRadius = previewLayer.frame.size.width/2
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
}

// MARK: - AVCapturePhotoCaptureDelegate

extension MessagesViewController: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        guard let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
            else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        guard let image = UIImage(data: dataImage) else {
            print("Error creating image from data: \(String(describing: error))")
            return
        }
        
        let rotatedImage = image.imageWithAdjustedOrientation(deviceOrientation: UIScreen.main.orientation)
        
        
        addSelfieImageToView(image: rotatedImage)
        
        guard let rotatedImageData = UIImageJPEGRepresentation(rotatedImage, 1) else {
            print("Unable to orientate photo: \(String(describing: error))")
            return
        }
        
        stopSession()
        
        let imageFileURL = URL.cachedFileURL(Constants.ImageFilename)
        
        do {
            try rotatedImageData.write(to: imageFileURL)
            notifyViewModelOf(imageUrl: imageFileURL)
        } catch {
            print("Error saving captured photo to disk")
            startSession()
        }
    }
}

// MARK: - Laying out selfie imageView and Info view

extension MessagesViewController {
    
    fileprivate func layoutSelfieView() {
        
        let subviews = selfieImageContainer.subviews.filter { $0 is UIImageView }
        
        if let selfieImageView = subviews.first as? UIImageView {
            guard let image = selfieImageView.image else {
                return
            }
            let dims = image.getBestFitDimsWithin(container: selfieImageContainer, scale: Constants.View.SelfieImageFill)
            selfieImageView.frame = CGRect(x: 0, y: 0, width: dims.width, height: dims.height)
            selfieImageView.center = CGPoint(x: selfieImageContainer.bounds.midX,
                                             y: selfieImageContainer.bounds.midY)
        }
    }
    
    fileprivate func addSelfieImageToView(image: UIImage) {
       
        let selfieImageView = UIImageView()
        
        selfieImageView.contentMode = .scaleAspectFit
        selfieImageView.image = image
        selfieImageView.layer.cornerRadius = 10
        selfieImageView.clipsToBounds = true
        
        let dims = image.getBestFitDimsWithin(container: selfieImageContainer, scale: Constants.View.SelfieImageFill)
        selfieImageView.frame = CGRect(x: 0, y: 0, width: dims.width, height: dims.height)
        selfieImageView.center = CGPoint(x: selfieImageContainer.bounds.midX,
                                        y: selfieImageContainer.bounds.midY)
        
        selfieImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        if selfieImageContainer.subviews.count > 0 {
            if let imageView = selfieImageContainer.subviews[0] as? UIImageView {
                imageView.removeFromSuperview()
                selfieImageContainer.addSubview(selfieImageView)
            }
        } else {
            selfieImageContainer.addSubview(selfieImageView)
        }
    }
    
    func layoutInfoView() {
        let subviews = view.subviews.filter { $0 is InfoView }
        
        if let infoView = subviews.first {
            infoView.removeFromSuperview()
            infoView.frame = CGRect(x: 0, y: 0 + topLayoutGuide.length, width: view.frame.size.width, height: 45)
        }
    }
}

// MARK: - UICollectionView binding and layout

extension MessagesViewController {
    
    fileprivate func bindCollectionView() {
        
        gifs.asObservable().bindTo(collectionView.rx.items(cellIdentifier: "gifCell", cellType: GifCell.self))
        { row, data, cell in
            cell.backgroundColor = UIColor().getRandom()
            cell.gif.sd_setImage(with: URL(string: data.image_url))
            }.addDisposableTo(disposeBag)
        
        collectionView.rx
            .itemSelected
            .subscribe(onNext: { indexPath in
                self.collectionView.isUserInteractionEnabled = false
                
                let gif = self.gifs.value[indexPath.row]
                
                guard let cell = self.collectionView.cellForItem(at: indexPath) else {
                    return
                }
                
                UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5, options: [],
                               animations: { cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) },
                               completion: { finished in
                                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 5, options: .curveEaseInOut,
                                               animations: { cell.transform = CGAffineTransform(scaleX: 1, y: 1) },
                                               completion: { finished in
                                                self.addGifToInputField(url: gif.image_url) {
                                                    self.collectionView.isUserInteractionEnabled = true
                                                }
                                }) }
                )
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func layoutCollectionView() {
        if let layout = collectionView?.collectionViewLayout as? GifCollectionViewLayout {
            layout.cache.removeAll()
            layout.numberOfColumns = UIScreen.main.orientation == .portrait ? 2 : 3
            layout.invalidateLayout()
            collectionView.backgroundView = nil
        }
        
        if gifs.value.count > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        } else {
            collectionView.backgroundView = placeHolderView
        }
    }
}

extension MessagesViewController : GifCollectionViewLayoutDelegate {
    
    func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let gif = gifs.value[indexPath.item]
        let boundingRect =  CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect  = AVMakeRect(aspectRatio: CGSize.init(width: gif.width, height: gif.height), insideRect: boundingRect)
        return rect.size.height
    }
}
