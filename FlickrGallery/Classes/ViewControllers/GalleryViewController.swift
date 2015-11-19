//
//  GalleryViewController.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 17/11/2015.
//
//

import UIKit
import CoreLocation
import CoreData
import FlickrKit
import MBProgressHUD

class GalleryViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    private let photosPerCell = 4
    private let refreshControl = UIRefreshControl()
    private let transitionDelegate = GalleryTransitionDelegate()
    private var isLoading = false
    private var lastLocation : CLLocation?
    
    var photos = [Photo]()
    
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
        
        loadImages()
        fetchLocation()
    }
    
    func fetchLocation() {
        KBLocationProvider.instance().startFetchLocation { (location, error) -> Void in
            if location != nil {
                
                if self.lastLocation == nil || location.distanceFromLocation(self.lastLocation!) > 50 {
                    self.fetchPhotos(location)
                }
                
                self.lastLocation = location
            }
            else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.showAlertError(error.localizedDescription)
                })
            }
        }
    }
    
    func fetchPhotos(location : CLLocation) {
        if !isLoading {
            isLoading = true;
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                hud.labelText = NSLocalizedString("LoadingPhotos", comment: "")
            })
            
            let photoSearch = FKFlickrPhotosSearch()
            photoSearch.accuracy = String(11) // Accuracy set to a city level
            photoSearch.lat = String(location.coordinate.latitude)
            photoSearch.lon = String(location.coordinate.longitude)
            
            let flickrKit = FlickrKit.sharedFlickrKit()
            flickrKit.call(photoSearch) { (response, error) -> Void in
                
                if (response != nil) {
                    let topPhotos = response["photos"] as! [NSObject: AnyObject]
                    let photoArray = topPhotos["photo"] as! [[NSObject: AnyObject]]
                    
                    var counter = 0
                    
                    for photoDictionary in photoArray {
                        var download = true
                        let imageUrl = flickrKit.photoURLForSize(FKPhotoSizeLarge1024, fromPhotoDictionary: photoDictionary)
                        
                        // Prevent downloading image from a known url in the database
                        for photo in self.photos {
                            let photoUrl = photo.url as String!
                            if photoUrl == imageUrl.absoluteString {
                                download = false
                                counter++
                                break
                            }
                        }
                        
                        // Download new images if necessary
                        if download {
                            self.downloadImage(imageUrl, completion: { (image, error) -> Void in
                                counter++
                                
                                // Save the downloaded images into the database
                                if image != nil {
                                    self.saveImage(imageUrl, image: image!)
                                }
                                
                                // Finalize the request by updating the UI
                                if counter == photoArray.count - 1 {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        self.finalizeSync()
                                    })
                                }
                            })
                        }
                        else {
                            // Finalize the request by updating the UI
                            if counter == photoArray.count - 1 {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.finalizeSync()
                                })
                            }
                        }
                    }
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.showAlertError(error.localizedDescription)
                        self.finalizeSync()
                    })
                }
            }
        }
    }
    
    func loadImages() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        do {
            photos = try managedContext.executeFetchRequest(fetchRequest) as! [Photo]
        } catch let error as NSError {
            print("Could not fetch photo from database \(error), \(error.userInfo)")
        }
    }
    
    func downloadImage(url: NSURL, completion: ((image: UIImage?, error: NSError?) -> Void)) {
        print("Start downloading image at url \(url)")
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            if data != nil {
                completion(image: UIImage(data: data!), error: nil)
            }
            else {
                completion(image: nil, error: error)
            }
        }.resume()
    }
    
    func saveImage(url: NSURL, image: UIImage) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext:managedContext)
        let photo = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext) as! Photo
        
        photo.url = url.absoluteString
        photo.image = UIImageJPEGRepresentation(image, 1)
        
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save photo in database : \(error), \(error.userInfo)")
        }
    }
    
    func showAlertError(message : String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func finalizeSync() {
        loadImages()
        
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        self.collectionView?.reloadData()
        self.refreshControl.endRefreshing()
        self.isLoading = false
    }
    
    func showZoomView(indexPath: NSIndexPath) {
        let attributes = collectionView?.layoutAttributesForItemAtIndexPath(indexPath)
        let attributesFrame = attributes?.frame
        let frameToOpenFrom = collectionView?.convertRect(attributesFrame!, toView: collectionView?.superview)
        transitionDelegate.openingFrame = frameToOpenFrom
        
        let zoomViewController = storyboard?.instantiateViewControllerWithIdentifier("zoom_storyboard_id") as! ZoomViewController
        zoomViewController.transitioningDelegate = transitionDelegate
        zoomViewController.modalPresentationStyle = .Custom
        
        let photo = photos[indexPath.row]
        if photo.image != nil {
            zoomViewController.image = UIImage(data: photo.image!)
        }
        
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
            if pinchLayout.pinchedCellScale > 2 {
                showZoomView(pinchLayout.pinchedCellPath)
            }
            
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
        
        let photo = photos[indexPath.row]
        if photo.image != nil {
            cell.photo.image = UIImage(data: photo.image!)
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        showZoomView(indexPath)
    }
    
}
