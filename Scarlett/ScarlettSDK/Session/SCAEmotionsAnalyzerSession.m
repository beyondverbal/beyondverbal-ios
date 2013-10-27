//
//  SCAEmotionsAnalyzerSession.m
//  Scarlett
//
//  Created by Daniel Galeev on 10/20/13.
//  Copyright (c) 2013 BeyondVerbals. All rights reserved.
//

#import "SCAEmotionsAnalyzerSession.h"

NSString* const SCAStartSessionUrlFormat = @"https://%@/v1/recording/start?api_key=%@";

@implementation SCAEmotionsAnalyzerSession

-(id)initWithSessionParameters:(SCASessionParameters*)sessionParameters
                        apiKey:(NSString*)apiKey
                requestTimeout:(NSTimeInterval)requestTimeout
       getAnalysisTimeInterval:(NSTimeInterval)getAnalysisTimeInterval
                          host:(NSString*)host
                      delegate:(id<SCAEmotionsAnalyzerSessionDelegate>)delegate
{
    if(self = [super init])
    {
        self.delegate = delegate;
        
        self.startSessionResponder = [[SCAStartSessionResponder alloc] init];
        self.startSessionResponder.delegate = self;
        self.upStreamVoiceResponder = [[SCAUpStreamVoiceResponder alloc] init];
        self.upStreamVoiceResponder.delegate = self;
        self.analysisResponder = [[SCAAnalysisResponder alloc] init];
        self.analysisResponder.delegate = self;
        self.summaryResponder = [[SCASummaryResponder alloc] init];
        self.summaryResponder.delegate = self;
        self.voteResponder = [[SCAVoteResponder alloc] init];
        self.voteResponder.delegate = self;
        
        _sessionParameters = sessionParameters;
        _apiKey = apiKey;
        
        self.requestTimeout = requestTimeout;
        self.getAnalysisTimeInterval = getAnalysisTimeInterval;
        self.host = host;
    }
    return self;
}

#pragma mark - Public methods

-(void)startSession
{
    _sessionStarted = YES;
    _lastAnalysisResult = nil;
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[_sessionParameters recorderInfoToDictionary] forKey:@"recorder_info"];
    [dictionary setObject:[_sessionParameters dataFormatToDictionary] forKey:@"data_format"];
    [dictionary setObject:[_sessionParameters requiredAnalysisTypesArray] forKey:@"requiredAnalysisTypes"];
    
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *jsonString =[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    
    NSLog(@"startSession %@", jsonString);
    
    SCAUrlRequest *request = [[SCAUrlRequest alloc] init];
    
    NSString *url = [NSString stringWithFormat:SCAStartSessionUrlFormat, self.host, _apiKey];
    
    [request loadWithUrl:url body:bodyData timeoutInterval:self.requestTimeout isStream:NO httpMethod:@"POST" delegate:self.startSessionResponder];
}

-(void)stopSession
{
    _sessionStarted = NO;
    
    [self stopStreamPostManager];
    
    [self stopAnalysisTimer];
}

-(void)upStreamVoiceData:(NSData*)voiceData
{
    if(_sessionStarted)
    {
        if(!self.streamPostManager)
        {
            self.streamPostManager = [[SCAStreamPostManager alloc] initWithDelegate:self.upStreamVoiceResponder];
            
            [self.streamPostManager startSend:_startSessionResult.followupActions.upStream];
        }
        
        [self.streamPostManager appendPostData:voiceData];
        
        if(!self.getAnalysisTimer)
        {
            [self startAnalysisTimer];
        }
    }
}

-(void)getSummary
{
    if(_lastAnalysisResult)
    {
        SCAUrlRequest *request = [[SCAUrlRequest alloc] init];
        
        NSString *url = _lastAnalysisResult.followupActions.summary;
        
        [request loadWithUrl:url body:nil timeoutInterval:self.requestTimeout isStream:NO httpMethod:@"GET" delegate:self.summaryResponder];
    }
    else
    {
        [self.delegate getSummaryFailed:@"Must recieve at least one analysis"];
    }
}

-(void)vote:(int)voteScore
{
    [self vote:voteScore verbalVote:nil];
}

-(void)vote:(int)voteScore verbalVote:(NSString*)verbalVote
{
    [self vote:voteScore verbalVote:verbalVote segment:nil];
}

-(void)vote:(int)voteScore verbalVote:(NSString*)verbalVote segment:(SCASegment*)segment
{
    if(_lastAnalysisResult)
    {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        
        if(segment)
        {
            [dictionary setObject:[NSNumber numberWithUnsignedLong:segment.offset] forKey:@"offset"];
            [dictionary setObject:[NSNumber numberWithUnsignedLong:segment.duration] forKey:@"duration"];
        }
        
        [dictionary setObject:[NSNumber numberWithInt:voteScore] forKey:@"vote"];
        
        if(verbalVote)
        {
            [dictionary setObject:verbalVote forKey:@"verbalVote"];
        }
        
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
        
        NSString *jsonString =[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        
        NSLog(@"vote %@", jsonString);
        
        SCAUrlRequest *request = [[SCAUrlRequest alloc] init];
        
        NSString *url = _lastAnalysisResult.followupActions.vote;
        
        [request loadWithUrl:url body:bodyData timeoutInterval:self.requestTimeout isStream:NO httpMethod:@"POST" delegate:self.voteResponder];
    }
    else
    {
        [self.delegate getSummaryFailed:@"Must recieve at least one analysis"];
    }
}

#pragma mark - Response

-(void)startSessionSucceed:(NSData *)responseData
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    NSLog(@"startSessionSucceed %@", jsonObject);
    
    _startSessionResult = [[SCAStartSessionResult alloc] initWithResponseData:responseData];
    
    if([_startSessionResult isSucceed])
    {
        [self.delegate startSessionSucceed];
    }
    else
    {
        [self.delegate startSessionFailed:_startSessionResult.reason];
    }
}

-(void)startSessionFailed:(NSError*)error
{
    [self.delegate startSessionFailed:[error localizedDescription]];
}

-(void)upStreamVoiceSucceed:(NSData *)responseData
{
    //TODO: parse response
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    NSLog(@"upStreamVoiceSucceed %@", jsonObject);
    
    [self.delegate upStreamVoiceDataSucceed];
}

-(void)upStreamVoiceFailed:(NSString *)errorDescription
{
    NSLog(@"upStreamVoiceFailed %@", errorDescription);
    
    [self stopSession];
    
    [self.delegate upStreamVoiceDataFailed:errorDescription];
}

-(void)getAnalysisSucceed:(NSData *)responseData
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    NSLog(@"getAnalysisSucceed %@", jsonObject);
    
    _lastAnalysisResult = [[SCAAnalysisResult alloc] initWithResponseData:responseData];
    
    if([_lastAnalysisResult isSessionStatusDone])
    {
        [self stopSession];
    }
    
    [self.delegate getAnalysisSucceed:_lastAnalysisResult];
}

-(void)getAnalysisFailed:(NSError *)error
{
    NSLog(@"analysisFailed %@", [error localizedDescription]);
    
    [self.delegate getAnalysisFailed:[error localizedDescription]];
}

-(void)getSummarySucceed:(NSData *)responseData
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    NSLog(@"getSummarySucceed %@", jsonObject);
    
    SCAAnalysisResult *analysisResult = [[SCAAnalysisResult alloc] initWithResponseData:responseData];
    
    [self.delegate getSummarySucceed:analysisResult];
}

-(void)getSummaryFailed:(NSError *)error
{
    NSLog(@"getSummaryFailed %@", [error localizedDescription]);
    
    [self.delegate getSummaryFailed:[error localizedDescription]];
}

-(void)voteSucceed:(NSData *)responseData
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    
    NSLog(@"voteSucceed %@", jsonObject);
    
    SCAVoteResult *voteResult = [[SCAVoteResult alloc] initWithResponseData:responseData];
    
    [self.delegate voteSucceed:voteResult];
}

-(void)voteFailed:(NSError *)error
{
    NSLog(@"voteFailed %@", [error localizedDescription]);
    
    [self.delegate voteFailed:[error localizedDescription]];
}

#pragma mark - Private methods

-(void)getAnalysisExecute:(NSTimer *)timer
{
    [self getAnalysis];
}

-(void)getAnalysis
{    
    SCAUrlRequest *request = [[SCAUrlRequest alloc] init];
    
    NSString *url = _startSessionResult.followupActions.analysis;
    
    if(_lastAnalysisResult)
    {
        url = _lastAnalysisResult.followupActions.analysis;
    }
    
    NSLog(@"getAnalysis %@", url);
    
    [request loadWithUrl:url body:nil timeoutInterval:self.requestTimeout isStream:NO httpMethod:@"GET" delegate:self.analysisResponder];
}

-(void)startAnalysisTimer
{
    self.getAnalysisTimer = [NSTimer scheduledTimerWithTimeInterval:self.getAnalysisTimeInterval
                                                             target:self
                                                           selector:@selector(getAnalysisExecute:)
                                                           userInfo:nil
                                                            repeats:YES];
}

-(void)stopAnalysisTimer
{
    if(self.getAnalysisTimer)
    {
        [self.getAnalysisTimer invalidate];
    }
    
    self.getAnalysisTimer = nil;
}

-(void)stopStreamPostManager
{
    if(self.streamPostManager)
    {
        [self.streamPostManager stopSend];
    }
    
    self.streamPostManager = nil;
}

@end
