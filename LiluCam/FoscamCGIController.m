//
//  FoscamCGIController.m
//  LiluCam
//
//  Created by Takashi Okamoto on 12/25/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import "FoscamCGIController.h"

// externs
NSString* const LCCameraMoveUp          = @"ptzMoveUp";
NSString* const LCCameraMoveDown        = @"ptzMoveDown";
NSString* const LCCameraMoveLeft        = @"ptzMoveLeft";
NSString* const LCCameraMoveRight       = @"ptzMoveRight";
NSString* const LCCameraMoveTopLeft     = @"ptzMoveTopLeft";
NSString* const LCCameraMoveTopRight    = @"ptzMoveTopRight";
NSString* const LCCameraMoveBottomLeft  = @"ptzMoveBottomLeft";
NSString* const LCCameraMoveBottomRight = @"ptzMoveBottomRight";
NSString* const LCCameraStop            = @"ptzStopRun";
NSString* const LCCameraReset           = @"ptzReset";

@interface NSDictionary (ParameterString)

- (NSString *)toParameterString;

@end

@implementation NSDictionary (ParameterString)

- (NSString *)toParameterString
{
    NSMutableString *str = nil;
    for (NSString *key in self) {
        NSString *escapeKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *escapeValue = [[self objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if (str == nil) {
            str = [[NSMutableString alloc] initWithFormat:@"%@=%@", escapeKey, escapeValue];
        } else {
            [str appendFormat:@"&%@=%@", escapeKey, escapeValue];
        }
    }
    return str;
}

@end


@interface FoscamCGIController () {
    NSString *_username;
    NSString *_password;
    NSString *_cgiPath;
    dispatch_queue_t backgroundQueue;
}

- (NSDictionary *)createParameterDictionaryWithDictionary:(NSDictionary *)dictionary;
- (NSString *)cgiPathForParameters:(NSDictionary *)params;
- (void)sendParameterPath:(NSString *)parameterPath withCompletionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (void)sendParametersWithDefault:(NSDictionary *)params;

@end


@implementation FoscamCGIController

- (id)initWithCGIPath:(NSString *)cgiPath username:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (self) {
        _cgiPath = cgiPath;
        _username = username;
        _password = password;
        // create background queue
        backgroundQueue = dispatch_queue_create("com.buzamoto.FoscamCGIController", NULL);
    }
    return self;
}


#pragma mark - Control Methods

- (void)setIRMode:(NSString *)mode
{
    NSString *val;
    if ([mode isEqualToString:@"manual"]) {
        val = @"1";
    } else {
        val = @"0";
    }
    
    NSDictionary *params = [self createParameterDictionaryWithDictionary:@{@"cmd" : @"setInfraLedConfig", @"mode" : val}];
    [self sendParametersWithDefault:params];
}

- (void)setIR:(BOOL)mode
{
    NSString *val;
    if (mode) {
        val = @"openInfraLed";
    } else {
        val = @"closeInfraLed";
    }
    
    NSDictionary *params = [self createParameterDictionaryWithDictionary:@{@"cmd" : val}];
    [self sendParametersWithDefault:params];
}


#pragma mark - Camera Movements
- (void)cameraMove:(NSString * const)direction
{
    NSDictionary *params = [self createParameterDictionaryWithDictionary:@{@"cmd": direction}];
    [self sendParametersWithDefault:params];
}

- (void)cameraMoveStop
{
    NSDictionary *params = [self createParameterDictionaryWithDictionary:@{@"cmd": LCCameraStop}];
    [self sendParametersWithDefault:params];
}


#pragma mark - Private Methods

- (NSDictionary *)createParameterDictionaryWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *parameterDictionary = [NSMutableDictionary dictionaryWithObjects:@[_username, _password] forKeys:@[@"usr", @"pwd"]];
    if (dictionary) {
        [parameterDictionary addEntriesFromDictionary:dictionary];
    }
    return (NSDictionary *)parameterDictionary;
}

- (NSString *)cgiPathForParameters:(NSDictionary *)params
{
    return [NSString stringWithFormat:@"%@?%@", _cgiPath, [params toParameterString]];
}

- (void)sendParameterPath:(NSString *)parameterPath withCompletionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
    dispatch_async(backgroundQueue, ^(void){
        NSURL *url = [NSURL URLWithString:parameterPath];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            // do some processing before calling the completion handler
            
            // like processing the XML in data
            
            // call completionHandler if defined
            if (completionHandler) {
                completionHandler(data, response, error);
            }
        }];
        [task resume];
    });
}

- (void)sendParametersWithDefault:(NSDictionary *)params
{
    NSString *paramsPath = [self cgiPathForParameters:params];
    
    [self sendParameterPath:paramsPath withCompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
        NSLog(@"Completed tasks for: %@", paramsPath);
    }];
}

@end
