//
//  KBLocationProvider.h
//  Winewoo
//
//  Created by Stephen Vinouze on 22/04/2015.
//  Copyright (c) 2015 Kasual Business. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^KBLocationCallback)(CLLocation *location, NSError *error);

@interface KBLocationProvider : NSObject <CLLocationManagerDelegate>

+ (KBLocationProvider *)instance;
+ (CLLocation *)lastLocation;
+ (void)reverseLocation:(CLGeocodeCompletionHandler)completionHandler;

- (void)startFetchLocation:(KBLocationCallback)completion;
- (void)startFetchLocation:(CLLocationAccuracy)accuracy completion:(KBLocationCallback)completion;
- (void)startFetchLocation:(CLLocationAccuracy)accuracy distance:(CLLocationDistance)distance completion:(KBLocationCallback)completion;
- (void)stopFetchLocation;

@end
