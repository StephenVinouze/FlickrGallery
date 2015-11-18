//
//  PinchLayout.h
//  CollectionViewTest
//
//  Created by Jeremias Nunez on 4/17/13.
//  Copyright (c) 2013 Jeremias Nunez. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PinchLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) CGFloat pinchedCellScale;
@property (nonatomic, assign) CGFloat pinchedCellRotationAngle; // in radians
@property (nonatomic, assign) CGPoint pinchedCellCenter;
@property (nonatomic, strong) NSIndexPath* pinchedCellPath;

@end
