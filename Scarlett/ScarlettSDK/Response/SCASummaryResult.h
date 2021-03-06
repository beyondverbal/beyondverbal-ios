//
//  SCASummaryResult.h
//  Scarlett
//
//  Created by Daniel Galeev on 10/20/13.
//  Copyright (c) 2013 BeyondVerbals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCAFollowupActions.h"
#import "SCAResponseStatuses.h"
#import "SCASessionStatuses.h"
#import "SCASummaryCollection.h"

@interface SCASummaryResult : NSObject

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *reason;
@property (nonatomic, strong) SCAFollowupActions *followupActions;
@property (nonatomic) unsigned long durationProcessed;
@property (nonatomic, strong) NSString *sessionStatus;
@property (nonatomic, strong) SCASummaryCollection *summaryCollection;

/**
 * Method name: initWithResponseData
 * Description: Initialize with response from server
 * Parameters:  responseData - response data from server
 */
-(id)initWithResponseData:(NSData*)responseData;

@end
