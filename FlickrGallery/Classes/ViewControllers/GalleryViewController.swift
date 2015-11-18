//
//  GalleryViewController.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 17/11/2015.
//
//

import UIKit
import FlickrKit
import SDWebImage
import MBProgressHUD

class GalleryViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    private let photosPerCell = 4
    private let refreshControl = UIRefreshControl()
    private var isLoading = false
    private var photos = [NSURL]()
    
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
                    self.fetchPhotos(location)
                }
                else {
                    self.showAlertError(error.localizedDescription)
                }
            })
        }
    }
    
    func fetchPhotos(location : CLLocation!) {
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
                            let photoURL = flickrKit.photoURLForSize(FKPhotoSizeSmall240, fromPhotoDictionary: photoDictionary)
                            self.photos.append(photoURL)
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
    
    func showAlertError(message : String!) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func onRefresh() {
        fetchPhotos(KBLocationProvider.lastLocation())
    }
    
    func onPinch(sender : UIPinchGestureRecognizer) {
        let pinchLayout = collectionView?.collectionViewLayout as! PinchLayout
        
        if sender.state == .Began {
            let initialPoint = sender.locationInView(collectionView)
            pinchLayout.pinchedCellPath = collectionView?.indexPathForItemAtPoint(initialPoint)
        }
        else if sender.state == .Changed {
            pinchLayout.pinchedCellScale = sender.scale
            pinchLayout.pinchedCellCenter = sender.locationInView(collectionView)
        }
        else {
            collectionView?.performBatchUpdates({ () -> Void in
                pinchLayout.pinchedCellPath = nil;
                pinchLayout.pinchedCellScale = 1.0;
                pinchLayout.pinchedCellRotationAngle = 0.0;
                }, completion: nil)
        }
    }
    
    func onRotate(sender : UIRotationGestureRecognizer) {
        let pinchLayout = collectionView?.collectionViewLayout as! PinchLayout
        
        if sender.state == .Began {
            let initialPoint = sender.locationInView(collectionView)
            pinchLayout.pinchedCellPath = collectionView?.indexPathForItemAtPoint(initialPoint)
        }
        else if sender.state == .Changed {
            pinchLayout.pinchedCellRotationAngle = sender.rotation
            pinchLayout.pinchedCellCenter = sender.locationInView(collectionView)
        }
        else {
            collectionView?.performBatchUpdates({ () -> Void in
                pinchLayout.pinchedCellPath = nil;
                pinchLayout.pinchedCellScale = 1.0;
                pinchLayout.pinchedCellRotationAngle = 0.0;
                }, completion: nil)
        }
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
        cell.photo.sd_setImageWithURL(photos[indexPath.row])
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
}
