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
    
    func handleGestures(gesture: UIGestureRecognizer) {
        if gesture.state == .Changed {
            if let pinchGesture = gesture as? UIPinchGestureRecognizer {
                scale = pinchGesture.scale
            }
            else if let rotationGesture = gesture as? UIRotationGestureRecognizer {
                rotation = rotationGesture.rotation
            }
            
            transformPhoto()
        }
        else if gesture.state == .Ended {
            
            if scale <= 0.5 {
                dismissViewControllerAnimated(true, completion: nil)
            }
            else {
                scale = 1
                rotation = 0
                
                [UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.transformPhoto()
                    }, completion: nil)]
            }
        }
    }
    
    func transformPhoto() {
        photo.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(rotation))
    }
    
    func onTap() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onPinch(sender : UIPinchGestureRecognizer) {
        handleGestures(sender)
    }
    
    func onRotate(sender : UIRotationGestureRecognizer) {
        handleGestures(sender)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isKindOfClass(UIPinchGestureRecognizer) && otherGestureRecognizer.isKindOfClass(UIRotationGestureRecognizer)
    }
    
}
