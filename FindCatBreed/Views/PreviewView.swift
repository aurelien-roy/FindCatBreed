//
//  PreviewView.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 15/03/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import UIKit
import AVKit


@IBDesignable
class PreviewView: UIView {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    
    
    
}
