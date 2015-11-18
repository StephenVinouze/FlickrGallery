//
//  PinchLayout.m
//  CollectionViewTest
//
//  Created by Jeremias Nunez on 4/17/13.
//  Copyright (c) 2013 Jeremias Nunez. All rights reserved.
//

#import "PinchLayout.h"

@implementation PinchLayout

#pragma mark - UICollectionViewLayout methods
- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* attribsArray = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes* attributes in attribsArray) {
        
        if ([attributes.indexPath isEqual:self.pinchedCellPath]) {
            attributes.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(self.pinchedCellScale, self.pinchedCellScale),
                                                           CGAffineTransformMakeRotation(self.pinchedCellRotationAngle));
            attributes.center = self.pinchedCellCenter;
            attributes.zIndex = 1;
        } else {
            attributes.zIndex = -1;
        }
    }
    
    return attribsArray;
}

#pragma mark - Setter methods
- (void)setPinchedCellScale:(CGFloat)scale
{
    if (_pinchedCellScale == scale) {
        return;
    }
    
    _pinchedCellScale = scale;
    [self invalidateLayout];
}

- (void)setPinchedCellCenter:(CGPoint)origin
{
    if (CGPointEqualToPoint(_pinchedCellCenter, origin)) {
        return;
    }
    
    _pinchedCellCenter = origin;
    [self invalidateLayout];
}

- (void)setPinchedCellRotationAngle:(CGFloat)pinchedCellRotationAngle
{
    if (_pinchedCellRotationAngle == pinchedCellRotationAngle) {
        return;
    }
    
    _pinchedCellRotationAngle = pinchedCellRotationAngle;
    [self invalidateLayout];
}

@end
