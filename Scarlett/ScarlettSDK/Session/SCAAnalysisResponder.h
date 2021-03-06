//
//  SCAStartSessionResponder.h
//  Scarlett
//
//  Created by Daniel Galeev on 10/20/13.
//  Copyright (c) 2013 BeyondVerbals. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCAAnalysisResponderDelegate.h"
#import "SCAUrlRequestDelegate.h"

@interface SCAAnalysisResponder : NSObject<SCAUrlRequestDelegate>

@property (nonatomic, weak) id<SCAAnalysisResponderDelegate> delegate;

@end
