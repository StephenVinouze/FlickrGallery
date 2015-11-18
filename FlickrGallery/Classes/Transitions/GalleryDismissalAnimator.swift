//
//  GalleryDismissalAnimator.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 18/11/2015.
//
//

import UIKit

class GalleryDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var openingFrame: CGRect?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let containerView = transitionContext.containerView()
        
        let animationDuration = self.transitionDuration(transitionContext)
        
        let snapshotView = fromViewController.view.resizableSnapshotViewFromRect(fromViewController.view.bounds, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        containerView?.addSubview(snapshotView)
        
        fromViewController.view.alpha = 0.0
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            snapshotView.frame = self.openingFrame!
            snapshotView.alpha = 0.0
            }) { (finished) -> Void in
                snapshotView.removeFromSuperview()
                fromViewController.view.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
}
