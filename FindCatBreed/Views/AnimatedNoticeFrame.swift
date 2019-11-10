//
//  AnimatedNoticeFrame.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 29/09/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import UIKit

class AnimatedNoticeFrame: UIView {
    
    typealias Notice = PaddingLabel
    
    var currentLabel: Notice?
    var dismissingLabel: Notice?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        
    }
    
    func setupView(){
        backgroundColor = .clear
        layer.masksToBounds = true
    }
    
    public func notice(_ message: String?) {
        
        if(currentLabel?.text == message) {
            return
        }
        
        if(dismissingLabel?.text == message) {
            let toDismiss = currentLabel
            let toRestore = dismissingLabel
            restoreMessage(toRestore)
            dismissMessage(toDismiss, inverted: true)
        } else {
            dismissMessage(currentLabel)
            
            if let m = message {
                spawnMessage(m)
            }
            
        }
        
        
    }
    
    private func spawnMessage(_ message: String) {
        let label = PaddingLabel()
        
        addSubview(label)
        
        label.bottomInset = 10
        label.topInset = 10
        label.leftInset = 20
        label.rightInset = 20
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.textAlignment = .center
        
        label.backgroundColor = UIColor(white: 1, alpha: 0.8)
        label.textColor = .systemIndigo
        
        label.text = message
        label.numberOfLines = 0
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        label.sizeToFit()
        label.transform = CGAffineTransform(translationX: 0, y: 40)
        label.layer.opacity = 0
        
        UIView.animate(
        withDuration: 0.5,
        delay: 0,
        options: .curveEaseOut,
        animations: {
            label.transform = CGAffineTransform(translationX: 0, y: 0)
            label.layer.opacity = 1
        },
        completion: nil)
        
        currentLabel = label
        
    }
    
    private func restoreMessage(_ messageToRestore: Notice?) {
        guard let label = messageToRestore else {
            return
        }
        
        //dismissingLabel = nil
        currentLabel = label
        label.layer.removeAllAnimations()
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                label.transform = CGAffineTransform(translationX: 0, y: 0)
                label.layer.opacity = 1
            }
        )
        
    }
    
    private func dismissMessage(_ messageToDismiss: Notice?, inverted: Bool = false) {
        
        guard let label = messageToDismiss else {
            return
        }
        
        self.dismissingLabel = label
        
        if currentLabel == label {
            currentLabel = nil
        }
        
        
        label.layer.removeAllAnimations()
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                label.transform = CGAffineTransform(translationX: 0, y: -40 * (inverted ? -1 : 1))
                label.layer.opacity = 0
            },
            completion: { finished in
                if finished {
                    label.removeFromSuperview()
                    if self.dismissingLabel == label {
                        self.dismissingLabel = nil
                    }
                    
                }
            }
        )
        
    }
}
