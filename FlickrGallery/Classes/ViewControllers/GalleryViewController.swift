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

class GalleryViewController : UICollectionViewController {
    
    private let refreshControl = UIRefreshControl()
    private var photos = [NSURL]()
    
    deinit {
        KBLocationProvider.instance().stopFetchLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        
        KBLocationProvider.instance().startFetchLocation(kCLLocationAccuracyHundredMeters) { (location, error) -> Void in
            if error == nil {
                self.fetchPhotos(location)
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.showAlertError("Pas de loc")
                })
            }
        }
    }
    
    func fetchPhotos(location : CLLocation!) {
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
            })
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
