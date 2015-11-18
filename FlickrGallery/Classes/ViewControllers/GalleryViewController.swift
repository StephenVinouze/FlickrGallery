//
//  GalleryViewController.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 17/11/2015.
//
//

import UIKit
import CoreLocation
import FlickrKit
import SDWebImage
import MBProgressHUD

class GalleryViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    private let photosPerCell = 4
    private let refreshControl = UIRefreshControl()
    private let transitionDelegate = GalleryTransitionDelegate()
    private var isLoading = false
    private var lastLocation : CLLocation?
    
    typealias Photo = (thumbnailImageUrl: NSURL, zoomImageUrl: NSURL?)
    
    var photos: [Photo] = []
    
    deinit {
        KBLocationProvider.instance().stopFetchLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: "onPinch:")
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: "onRotate:")
        
        pinchGesture.delegate = self
        rotateGesture.delegate = self
        
        collectionView?.collectionViewLayout = PinchLayout()
        collectionView?.addGestureRecognizer(pinchGesture)
        collectionView?.addGestureRecognizer(rotateGesture)
        
        KBLocationProvider.instance().startFetchLocation { (location, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if location != nil {
                    
                    if self.lastLocation == nil || location.distanceFromLocation(self.lastLocation!) > 10 {
                        self.fetchPhotos(location)
                    }
                    
                    self.lastLocation = location
                }
                else {
                    self.showAlertError(error.localizedDescription)
                }
            })
        }
    }
    
    func fetchPhotos(location : CLLocation) {
        if !isLoading {
            isLoading = true;
            
            let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            hud.labelText = NSLocalizedString("LoadingPhotos", comment: "")
            
            let photoSearch = FKFlickrPhotosSearch()
            photoSearch.accuracy = String(11) // Accuracy set to a city level
            photoSearch.lat = String(location.coordinate.latitude)
            photoSearch.lon = String(location.coordinate.longitude)
            
            let flickrKit = FlickrKit.sharedFlickrKit()
            flickrKit.call(photoSearch) { (response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if (response != nil) {
                        self.photos.removeAll()
                        
                        let topPhotos = response["photos"] as! [NSObject: AnyObject]
                        let photoArray = topPhotos["photo"] as! [[NSObject: AnyObject]]
                        for photoDictionary in photoArray {
                            let thumbnailImageUrl = flickrKit.photoURLForSize(FKPhotoSizeSmall240, fromPhotoDictionary: photoDictionary)
                            let zoomImageUrl = flickrKit.photoURLForSize(FKPhotoSizeLarge1024, fromPhotoDictionary: photoDictionary)
                            
                            self.photos.append((thumbnailImageUrl: thumbnailImageUrl, zoomImageUrl: zoomImageUrl))
                        }
                    }
                    else {
                        self.showAlertError(error.localizedDescription)
                    }
                    
                    hud.hide(true)
                    self.collectionView?.reloadData()
                    self.refreshControl.endRefreshing()
                    self.isLoading = false
                })
            }
        }
    }
    
    func showAlertError(message : String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showZoomView(indexPath: NSIndexPath) {
        let attributes = collectionView?.layoutAttributesForItemAtIndexPath(indexPath)
        let attributesFrame = attributes?.frame
        let frameToOpenFrom = collectionView?.convertRect(attributesFrame!, toView: collectionView?.superview)
        transitionDelegate.openingFrame = frameToOpenFrom
        
        let zoomViewController = storyboard?.instantiateViewControllerWithIdentifier("zoom_storyboard_id") as! ZoomViewController
        zoomViewController.imageUrl = photos[indexPath.row].zoomImageUrl
        zoomViewController.transitioningDelegate = transitionDelegate
        zoomViewController.modalPresentationStyle = .Custom
        
        //navigationController?.pushViewController(zoomViewController, animated: true)
        presentViewController(zoomViewController, animated: true, completion: nil)
    }
    
    func handleGesture(gesture: UIGestureRecognizer) {
        let pinchLayout = collectionView?.collectionViewLayout as! PinchLayout
        
        if gesture.state == .Began {
            let initialPoint = gesture.locationInView(collectionView)
            pinchLayout.pinchedCellPath = collectionView?.indexPathForItemAtPoint(initialPoint)
        }
        else if gesture.state == .Changed {
            pinchLayout.pinchedCellCenter = gesture.locationInView(collectionView)
            
            if let pinchGesture = gesture as? UIPinchGestureRecognizer {
                pinchLayout.pinchedCellScale = pinchGesture.scale
            }
            else if let rotationGesture = gesture as? UIRotationGestureRecognizer {
                pinchLayout.pinchedCellRotationAngle = rotationGesture.rotation
            }
        }
        else {
            collectionView?.performBatchUpdates({ () -> Void in
                pinchLayout.pinchedCellPath = nil;
                pinchLayout.pinchedCellScale = 1.0;
                pinchLayout.pinchedCellRotationAngle = 0.0;
                }, completion: nil)
        }
    }
    
    
    func onPinch(gesture : UIPinchGestureRecognizer) {
        handleGesture(gesture)
    }
    
    func onRotate(gesture : UIRotationGestureRecognizer) {
        handleGesture(gesture)
    }
    
    func onRefresh() {
        fetchPhotos(KBLocationProvider.lastLocation())
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isKindOfClass(UIPinchGestureRecognizer) && otherGestureRecognizer.isKindOfClass(UIRotationGestureRecognizer)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let photoDimension : CGFloat = (UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 150 : 100
        return  CGSizeMake(photoDimension, photoDimension)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("gallery_cell_identifier", forIndexPath: indexPath) as! GalleryCell
        cell.photo.sd_setImageWithURL(photos[indexPath.row].thumbnailImageUrl)
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        showZoomView(indexPath)
    }
    
}
