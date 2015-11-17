//
//  KBLocationProvider.m
//  Winewoo
//
//  Created by Stephen Vinouze on 22/04/2015.
//  Copyright (c) 2015 Kasual Business. All rights reserved.
//

#import "KBLocationProvider.h"

static CLLocation *kLocation;
static KBLocationProvider *kSingleton;

@interface KBLocationProvider ()
{
    CLLocationManager *_locationManager;
    
    KBLocationCallback _callback;
}

@end

@implementation KBLocationProvider

+ (KBLocationProvider *)instance
{
    if (!kSingleton) {
        kSingleton = [KBLocationProvider new];
    }
    return kSingleton;
}

+ (CLLocation *)lastLocation
{
    return kLocation;
}

+ (void)reverseLocation:(CLGeocodeCompletionHandler)completionHandler
{
    if (kLocation) {
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:kLocation completionHandler:completionHandler];
    }
    else {
        completionHandler(nil, [NSError errorWithDomain:kCLErrorDomain code:kCLErrorLocationUnknown userInfo:nil]);
    }
}

- (void)startFetchLocation:(CLLocationAccuracy)accuracy completion:(KBLocationCallback)completion
{
    _callback = completion;
    
    _locationManager = [[CLLocationManager alloc] init];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    [_locationManager setDesiredAccuracy:accuracy];
    [_locationManager setDelegate:self];
    [_locationManager startUpdatingLocation];
}

- (void)stopFetchLocation
{
    [_locationManager stopUpdatingLocation];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Failed to get location with error: %@", error);
    
    _callback(nil, error);
}

- (void )locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"Fetching new location = %@", [locations lastObject]);
    kLocation = [locations lastObject];
    
    _callback(kLocation, nil);
}

@end
