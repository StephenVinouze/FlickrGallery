//
//  GalleryTransitionDelegate.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 18/11/2015.
//
//

import UIKit

class GalleryTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var openingFrame: CGRect?
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentationAnimator = GalleryPresentationAnimator()
        presentationAnimator.openingFrame = openingFrame!
        return presentationAnimator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let dismissAnimator = GalleryDismissalAnimator()
        dismissAnimator.openingFrame = openingFrame!
        return dismissAnimator
    }
}
