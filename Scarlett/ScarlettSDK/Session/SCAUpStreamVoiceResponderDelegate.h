//
//  SCAStartSessionResponderDelegate.h
//  Scarlett
//
//  Created by Daniel Galeev on 10/20/13.
//  Copyright (c) 2013 BeyondVerbals. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCAUpStreamVoiceResponderDelegate <NSObject>
-(void)upStreamVoiceSucceed:(NSData*)responseData;
-(void)upStreamVoiceFailed:(NSString*)errorDescription;
-(void)upStreamVoiceStopped;
@end
