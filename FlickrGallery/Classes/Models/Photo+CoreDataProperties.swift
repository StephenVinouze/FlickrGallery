//
//  Photo+CoreDataProperties.swift
//  FlickrGallery
//
//  Created by Stephen Vinouze on 18/11/2015.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var url: String?
    @NSManaged var image: NSData?

}
