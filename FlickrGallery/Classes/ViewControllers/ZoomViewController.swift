//
//  ZoomViewController.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 18/11/2015.
//
//

import UIKit
import SDWebImage

class ZoomViewController : UIViewController, UIGestureRecognizerDelegate {
    
    var imageUrl : NSURL?
    private var scale :CGFloat = 1
    private var rotation :CGFloat = 0
    
    @IBOutlet weak var photo : UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photo.sd_setImageWithURL(imageUrl)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "onTap")
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: "onPinch:")
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: "onRotate:")
        
        pinchGesture.delegate = self
        rotateGesture.delegate = self
        
        view.backgroundColor = UIColor.clearColor()
        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(pinchGesture)
        view.addGestureRecognizer(rotateGesture)
    }
    
    func onTap() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onPinch(sender : UIPinchGestureRecognizer) {
        if sender.state == .Changed {
            scale = sender.scale
        }
        else if sender.state == .Ended {
            
            if sender.scale <= 0.5 {
                dismissViewControllerAnimated(true, completion: nil)
                return
            }
            
            scale = 1
            rotation = 0
        }
        photo.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(rotation))
    }
    
    func onRotate(sender : UIRotationGestureRecognizer) {
        if sender.state == .Changed {
            rotation = sender.rotation
        }
        else if sender.state == .Ended {
            scale = 1
            rotation = 0
        }
        photo.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(rotation))
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isKindOfClass(UIPinchGestureRecognizer) && otherGestureRecognizer.isKindOfClass(UIRotationGestureRecognizer)
    }
    
}
