//
//  PreviewViewController.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 19/03/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Vision

class PreviewViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    var captureSession : AVCaptureSession!
    var previewView: PreviewView { return self.view as! PreviewView }

    @IBOutlet var shapeView: UIView!
    @IBOutlet var animatedNoticeView: AnimatedNoticeFrame!
    
    @objc var cameraDevice : AVCaptureDevice?
    
    var videoOutput : AVCaptureVideoDataOutput!
    var statusBarHidden = false
    var orientation : AVCaptureVideoOrientation?
    
    var isLive : Bool = false
    
    var analyzer: CatAnalyzer!
    
    var successiveFramesWithOneCat = 0
    var intermediateResults: [CatAnalyzer.ClassificationResult] = []
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { get { return .fade } }
    override var prefersStatusBarHidden: Bool { return statusBarHidden }
    
    
    // Detection parameters
    
    let REQUIRED_CAPTURES = 4 // Number of images used for classifications
    let FRAMES_BETWEEN_CAPTURES = 2 // Interval of frames between two captures
    
    override func viewDidLoad() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        
        do {
            analyzer = try CatAnalyzer()
        } catch {
            fatalError("Unable to initialize CatAnalyzer")
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: NSNotification){
        checkAuthorizations()
    }
    
    @objc func applicationDidEnterBackground(_ notification: NSNotification){
        if let session = captureSession{
            session.stopRunning()
        }
    }

    
    func checkAuthorizations(){
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.setupCaptureSession()
                
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setupCaptureSession()
                    }
                }
                
            case .denied: // The user has previously denied access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setupCaptureSession()
                    } else {
                        let alert = UIAlertController(title: "Autorisation", message: "Veuillez autoriser l'utilisation de la caméra dans les paramètres.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {
                            action in
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }))
                        
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            case .restricted: // The user can't grant access due to restrictions.
                return
            @unknown default:
                return
        }
    }
    
    
    func setupCaptureSession(){
        
        // Init capture session
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        // Setup video output
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        // Setup camera device
        cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        if(cameraDevice!.isFocusModeSupported(.continuousAutoFocus)) {
            try! cameraDevice!.lockForConfiguration()
            cameraDevice!.focusMode = .continuousAutoFocus
            cameraDevice!.unlockForConfiguration()
        }
        
        guard let cameraDeviceInput = try? AVCaptureDeviceInput(device: cameraDevice!),
            captureSession.canAddInput(cameraDeviceInput)
            else { fatalError("Can't add input") }
        
        
        // Link input and output
        captureSession.addInput(cameraDeviceInput)
        captureSession.sessionPreset = .hd1280x720
        captureSession.addOutput(videoOutput)
        
        captureSession.commitConfiguration()
        
        previewView.videoPreviewLayer.session = captureSession
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        captureSession.startRunning()
    }

    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imgbuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        connection.videoOrientation = .portrait
        
        let image = CIImage(cvImageBuffer: imgbuffer!)
        let size = CVImageBufferGetEncodedSize(imgbuffer!)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        analyzer.createDetectionTask(from: image){ boxs in
            
            DispatchQueue.main.async {
                self.processDetectionResults(boxs, capture_size: size, image: image)
                semaphore.signal()
            }
        }
        
        let _ = semaphore.wait(timeout: .now() + 2.0)
    }
    
    
    private func processDetectionResults(_ boxs: [CGRect], capture_size: CGSize, image: CIImage) {
        self.drawVisionSquares(boxs: boxs, videoSize: capture_size)
        
        if boxs.count != 1 || !self.isLive {
            self.successiveFramesWithOneCat = 0
            self.intermediateResults.removeAll()
            
            if(boxs.count == 0) {
                self.animatedNoticeView!.notice("Pointez la caméra vers un chat")
            } else {
                self.animatedNoticeView!.notice("Il y a plus d'un chat")
            }
        } else {
            self.animatedNoticeView!.notice("Maintenez un instant")
            self.successiveFramesWithOneCat += 1
        }
        
        // Wait for stabilization
        if (
            (self.successiveFramesWithOneCat-1) % self.FRAMES_BETWEEN_CAPTURES == 0 &&
                self.successiveFramesWithOneCat <= self.FRAMES_BETWEEN_CAPTURES * (self.REQUIRED_CAPTURES - 1) + 1 // self.FRAMES_BETWEEN_CAPTURES
            )  {
            
            debugPrint("runing task \(self.successiveFramesWithOneCat)")
            let croppedImage = self.cropImageWithRect(image, rect: boxs.first!)
            
            self.analyzer.createClassificationTask(from: CIImage(cgImage: croppedImage)){ results in
                DispatchQueue.main.async {
                    self.intermediateResults.append(results)
                    
                    if(self.intermediateResults.count >= self.REQUIRED_CAPTURES) {
                        self.showResults(
                            self.analyzer.mergeResults(self.intermediateResults),
                        image: croppedImage)
                    }
                }
            }
        }
    }
    
    private func showResults(_ results: [(String, Float)], image: CGImage) {
        let resultController = ResultViewController.storyboardInstance()!
        
        
        navigationController?.pushViewController(resultController, animated: true)
        resultController.image = image
        resultController.results = results
    }
    
    private func cropImageWithRect(_ image: CIImage, rect: CGRect) -> CGImage {
        
        let biggerRect = rect.insetBy(dx: -0.2*rect.width, dy: -0.2*rect.height)
        
        let vw = image.extent.width, vh = image.extent.height
        let unitToImage = CGAffineTransform(scaleX: vw, y: vh)
        
        let ciCroppedImage = image.cropped(to: biggerRect.applying(unitToImage))
        let context = CIContext()
        
        return context.createCGImage(ciCroppedImage, from:ciCroppedImage.extent)!
    }
    
    private func drawVisionSquares(boxs: [CGRect], videoSize: CGSize) {
        shapeView.layer.sublayers?.filter({ $0 is CAShapeLayer }).forEach({ $0.removeFromSuperlayer() })
        
        //lastObservationPosition = nil
        boxs.forEach { (box: CGRect) in
            let mask = CAShapeLayer()
            
            let vw = videoSize.width, vh = videoSize.height
 
            let unitToVideo = CGAffineTransform(scaleX: vw, y: vh)
            let screenVideoRatio = (view.bounds.width / vw, view.bounds.height / vh)
            let videoToScreenScale = CGAffineTransform(scaleX: screenVideoRatio.1, y: screenVideoRatio.1)
            let videoFitTranslate = CGAffineTransform(translationX: -0.5 * (vw * screenVideoRatio.1 - view.bounds.width), y: 0)
            let originChange = CGAffineTransform(translationX: 0, y: 1).scaledBy(x: 1, y: -1)
            
            let uiBoundingBox = box.applying(originChange).applying(unitToVideo).applying(videoToScreenScale).applying(videoFitTranslate)
 
            mask.frame = uiBoundingBox
            mask.cornerRadius = 2.0
            mask.opacity = 1
            mask.borderColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 0.2, 0.2, 1])
            mask.borderWidth = 2.0
            
            self.shapeView.layer.addSublayer(mask)
            
        }
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            videoPreviewLayerConnection.videoOrientation = transformOrientation(orientation: deviceOrientation)
        }
    }
    
    func transformOrientation(orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portrait
        default:
            return .portrait
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        statusBarHidden = false
        isLive = false
        
        // Show the Navigation Bar
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        debugPrint("did disappear")
        
        super.viewDidDisappear(animated)
        guard let session = captureSession else {
            return
        }
        
        session.stopRunning()
        
        isLive = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.statusBarHidden = true
        
        isLive = false
        
        UIView.animate(withDuration: 0.35) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        // Hide the Navigation Bar
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if let session = captureSession {
            session.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isLive = true

        animatedNoticeView!.notice("Pointez la caméra vers un chat")
        
    }
        
    
}
