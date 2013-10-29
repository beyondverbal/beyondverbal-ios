//
//  EmotionsAnalyzer.m
//  Scarlett
//
//  Created by Daniel Galeev on 10/28/13.
//  Copyright (c) 2013 BeyondVerbals. All rights reserved.
//

#import "SCAEmotionsAnalyzer.h"

@implementation SCAEmotionsAnalyzer

-(id)initWithApiKey:(NSString*)apiKey
     requestTimeout:(NSTimeInterval)requestTimeout
getAnalysisTimeInterval:(NSTimeInterval)getAnalysisTimeInterval
               host:(NSString*)host
    sessionDelegate:(id<SCAEmotionsAnalyzerSessionDelegate>)sessionDelegate
{
    if(self = [super init])
    {
        _apiKey = apiKey;
        _requestTimeout = requestTimeout;
        _getAnalysisTimeInterval = getAnalysisTimeInterval;
        _host = host;
        _sessionDelegate = sessionDelegate;
    }
    return self;
}

-(SCAEmotionsAnalyzerSession*)initializeSession:(SCASessionParameters*)sessionParameters
{
    SCAEmotionsAnalyzerSession *emotionsAnalyzerSession = [[SCAEmotionsAnalyzerSession alloc] initWithSessionParameters:sessionParameters apiKey:_apiKey requestTimeout:_requestTimeout getAnalysisTimeInterval:_getAnalysisTimeInterval host:_host sessionDelegate:_sessionDelegate];
    
    return emotionsAnalyzerSession;
}

@end
