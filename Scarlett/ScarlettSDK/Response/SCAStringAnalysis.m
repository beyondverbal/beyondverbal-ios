//
//  SCAStringAnalysis.m
//  Scarlett
//
//  Created by Daniel Galeev on 10/20/13.
//  Copyright (c) 2013 BeyondVerbals. All rights reserved.
//

#import "SCAStringAnalysis.h"

@implementation SCAStringAnalysis

-(id)initWithDictionary:(NSDictionary*)dictionary
{
    if(self = [super init])
    {
        self.value = [dictionary objectForKey:@"value"];
    }
    return self;
}

-(BOOL)isLow
{
    return [self.value isEqualToString:kTemperMeterLow];
}

-(BOOL)isMed
{
    return [self.value isEqualToString:kTemperMeterMed];
}

-(BOOL)isHigh
{
    return [self.value isEqualToString:kTemperMeterHigh];
}

@end
