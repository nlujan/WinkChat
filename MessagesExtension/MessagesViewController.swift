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
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate let gifViewModel = GifViewModel()
    fileprivate let gifs = Variable<[Gif]>([])
    fileprivate var currentOrientation: UIInterfaceOrientation = .portrait
    fileprivate var photoCaptureViewModel = PhotoCaptureViewModel()
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet var cameraView: SpinningView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var placeHolderView: UITextView!
    @IBOutlet var bottomViewContainer: UIView!
    @IBOutlet var bottomContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var selfieImageContainer: UIView!
    
    @IBOutlet var cameraButton: UIButton!
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        layoutInfoView()
    }
}

// MARK: - UIViewController Overload Methods

extension MessagesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutBottomViewContainer()
        layoutPreviewLayer()
        layoutCollectionView()
        bindCollectionView()
        bindViewModels()
        
        if RxReachability.shared.startMonitor(Constants.Giphy.Url) == false {
            print("Reachability failed!")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photoCaptureViewModel.startSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        photoCaptureViewModel.stopSession()
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
    
    fileprivate func bindViewModels() {
        
        gifViewModel
            .randomGifSubject
            .map { $0.image_url }
            .subscribe(onNext: { [unowned self] url in
                self.addGifToInputField(url: url)
                self.photoCaptureViewModel.startSession()
            })
            .disposed(by: disposeBag)
        
        gifViewModel
            .searchGifsSubject
            .subscribe(onNext: { [unowned self] gifs in
                self.gifs.value = gifs
                self.layoutCollectionView()
                self.photoCaptureViewModel.startSession()
            })
            .disposed(by: disposeBag)
        
        gifViewModel
            .errorSubject
            .subscribe(onNext: { [unowned self] error in
                switch error as! APIError {
                    case .NoFaceDetected:
                        InfoView.showIn(viewController: self, message: Constants.ErrorMessage.NoFaceDetected)
                    case .NoGifRecieved:
                        InfoView.showIn(viewController: self, message: Constants.ErrorMessage.NetworkIssue)
                }
                self.photoCaptureViewModel.startSession()
            })
            .disposed(by: disposeBag)
        
        photoCaptureViewModel
            .imageDataSubject
            .subscribe(onNext: { [unowned self] data in
                self.handleCameraImage(data: data)
            })
            .disposed(by: disposeBag)
        
        cameraButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.photoCaptureViewModel.takePhoto()
            })
            .disposed(by: disposeBag)
        
        Observable.from([
            gifViewModel.randomUrlSubject.map { _ in true },
            gifViewModel.searchUrlSubject.map { _ in true },
            gifViewModel.searchGifsSubject.map { _ in false }.filter { [unowned self] _ in
                self.presentationStyle == .expanded
            },
            gifViewModel.errorSubject.map { _ in false }
            ]).merge()
            .asDriver(onErrorJustReturn: false)
            .asObservable()
            .subscribe(onNext: { [unowned self] isRunning in
                self.cameraView.animating = isRunning
            })
            .disposed(by: disposeBag)
        
        Observable.from([
            cameraButton.rx.tap.map { _ in false },
            gifViewModel.searchGifsSubject.map { _ in true }.filter { [unowned self] _ in
                self.presentationStyle == .expanded
            },
            gifViewModel.errorSubject.map { _ in true }
            ]).merge()
            .asDriver(onErrorJustReturn: true)
            .drive(cameraButton.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)
    }
    
    fileprivate func notifyViewModelOf(imageUrl: URL) {
        
        guard RxReachability.shared.isOnline() else {
            InfoView.showIn(viewController: self, message: Constants.ErrorMessage.NetworkIssue)
            photoCaptureViewModel.startSession()
            return
        }
        if presentationStyle == .compact {
            gifViewModel.randomUrlSubject.onNext(imageUrl)
            gifViewModel.searchUrlSubject.onNext(imageUrl)
        } else {
            gifViewModel.searchUrlSubject.onNext(imageUrl)
        }
    }
}

// MARK: - Conversation Interaction Functions

extension MessagesViewController {
    
    fileprivate func addGifToInputField(url: String, closure: (() -> Void)? = nil) {
        
        if presentationStyle == .expanded {
            requestPresentationStyle(.compact)
        }
        
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        
        guard let bundleURL = URL(string: url) else {
            gifViewModel.errorSubject.onNext(APIError.NoGifRecieved)
            print("Error: This image named \"\(url)\" does not exist")
            return
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            gifViewModel.errorSubject.onNext(APIError.NoGifRecieved)
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
                self.gifViewModel.errorSubject.onNext(APIError.NoGifRecieved)
                print(error)
            }
            closure?()
        }
    }
}

// MARK: - Laying out bottom view container

extension MessagesViewController {
    
    fileprivate func layoutBottomViewContainer() {
        if UIScreen.main.bounds.height > 667 {
            bottomContainerHeightConstraint.constant = 227
            bottomViewContainer.layoutIfNeeded()
        }
    }
    
    fileprivate func layoutPreviewLayer() {
        previewLayer = photoCaptureViewModel.previewLayer
        previewLayer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        cameraView.layer.addSublayer(previewLayer)
        previewLayer.frame = cameraView.bounds.insetBy(dx: cameraView.lineWidth, dy: cameraView.lineWidth)
        cameraView.layer.cornerRadius = cameraView.frame.size.width/2
        previewLayer.cornerRadius = previewLayer.frame.size.width/2
        previewLayer.setOrientation(orientation: UIScreen.main.orientation)
    }
    
    fileprivate func layoutSelfieView() {
        
        let subviews = selfieImageContainer.subviews.filter { $0 is UIImageView }
        
        guard let selfieImageView = subviews.first as? UIImageView else {
            return
        }
        
        guard let image = selfieImageView.image else {
            return
        }
        
        let dims = image.getBestFitDimsWithin(container: selfieImageContainer, scale: Constants.View.SelfieImageFill)
        
        selfieImageView.frame = CGRect(x: 0, y: 0, width: dims.width, height: dims.height)
        selfieImageView.center = CGPoint(x: selfieImageContainer.bounds.midX,
                                         y: selfieImageContainer.bounds.midY)
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
    
    fileprivate func layoutInfoView() {
        let subviews = view.subviews.filter { $0 is InfoView }
        
        if let infoView = subviews.first {
            infoView.removeFromSuperview()
            infoView.frame = CGRect(x: 0, y: 0 + topLayoutGuide.length, width: view.frame.size.width, height: 45)
        }
    }
    
    func handleCameraImage(data: Data) {
        guard let image = UIImage(data: data) else {
            print("Error creating image from data")
            return
        }

        let rotatedImage = image.imageWithAdjustedOrientation(deviceOrientation: UIScreen.main.orientation)


        addSelfieImageToView(image: rotatedImage)

        guard let rotatedImageData = UIImageJPEGRepresentation(rotatedImage, 1) else {
            print("Unable to orientate photo")
            return
        }

        photoCaptureViewModel.stopSession()

        let imageFileURL = URL.cachedFileURL(Constants.ImageFilename)

        do {
            try rotatedImageData.write(to: imageFileURL)
            notifyViewModelOf(imageUrl: imageFileURL)
        } catch {
            print("Error saving captured photo to disk")
            photoCaptureViewModel.startSession()
        }
    }
}

// MARK: - UICollectionView Item selected delegate and layout

extension MessagesViewController {
    
    fileprivate func bindCollectionView() {
        
//        collectionView.rx
//            .itemSelected
//            .subscribe(onNext: { indexPath in
//                self.collectionView.isUserInteractionEnabled = false
//
//                let gif = self.gifs.value[indexPath.row]
//
//                guard let cell = self.collectionView.cellForItem(at: indexPath) else {
//                    return
//                }
//
//                UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5, options: [],
//                               animations: { cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) },
//                               completion: { finished in
//                                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 5, options: .curveEaseInOut,
//                                               animations: { cell.transform = CGAffineTransform(scaleX: 1, y: 1) },
//                                               completion: { finished in
//                                                self.addGifToInputField(url: gif.image_url) {
//                                                    self.collectionView.isUserInteractionEnabled = true
//                                                }
//                                }) }
//                )
//            })
//            .disposed(by: disposeBag)
        
    }
    
    fileprivate func layoutCollectionView() {
        
        if let layout = collectionView?.collectionViewLayout as? GifCollectionViewLayout {
            if layout.delegate == nil {
                layout.delegate = self
            }
            layout.cache.removeAll()
            layout.numberOfColumns = UIScreen.main.orientation == .portrait ? 2 : 3
            layout.invalidateLayout()
            collectionView.backgroundView = nil
            collectionView.reloadData()
        }
        
        if gifs.value.count > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        } else {
            collectionView.backgroundView = placeHolderView
        }
    }
}

// MARK: - UICollectionView GifCollectionViewLayoutDelegate

extension MessagesViewController : GifCollectionViewLayoutDelegate {
    
    func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
        let gif = gifs.value[indexPath.item]
        let boundingRect =  CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT))
        let rect  = AVMakeRect(aspectRatio: CGSize.init(width: gif.width, height: gif.height), insideRect: boundingRect)
        return rect.size.height
    }
}

// MARK: - UICollectionView UICollectionViewDataSource

extension MessagesViewController : UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gifCell", for: indexPath) as! GifCell
        cell.backgroundColor = UIColor().getRandom()
        cell.gif.sd_setImage(with: URL(string: gifs.value[indexPath.row].image_url))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    
        switch kind {
        case UICollectionElementKindSectionFooter:
            
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
            return footerView
            
        default:
            return UICollectionReusableView()
        }
    }
}


