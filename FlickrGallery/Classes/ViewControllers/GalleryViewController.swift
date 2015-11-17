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

class GalleryViewController : UICollectionViewController {
    
    private let refreshControl = UIRefreshControl()
    private var photos = [NSURL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.addTarget(self, action: "onRefresh", forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
        
        fetchPhotos()
    }
    
    func fetchPhotos() {
        let flickrKit = FlickrKit.sharedFlickrKit()
        flickrKit.call(FKFlickrInterestingnessGetList()) { (response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if (response != nil) {
                    let topPhotos = response["photos"] as! [NSObject: AnyObject]
                    let photoArray = topPhotos["photo"] as! [[NSObject: AnyObject]]
                    for photoDictionary in photoArray {
                        let photoURL = flickrKit.photoURLForSize(FKPhotoSizeSmall240, fromPhotoDictionary: photoDictionary)
                        self.photos.append(photoURL)
                    }
                }
                else {
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                
                self.collectionView?.reloadData()
                self.refreshControl.endRefreshing()
            })
        }
    }
    
    func onRefresh() {
        fetchPhotos()
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("gallery_cell_identifier", forIndexPath: indexPath) as! GalleryCell
        cell.backgroundColor = UIColor.blackColor()
        cell.photo.sd_setImageWithURL(photos[indexPath.row])
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
}
