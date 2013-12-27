//
//  FoscamCGIController.h
//  LiluCam
//
//  Created by Takashi Okamoto on 12/25/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const LCCameraMoveUp;
extern NSString* const LCCameraMoveDown;
extern NSString* const LCCameraMoveLeft;
extern NSString* const LCCameraMoveRight;
extern NSString* const LCCameraMoveTopLeft;
extern NSString* const LCCameraMoveTopRight;
extern NSString* const LCCameraMoveBottomLeft;
extern NSString* const LCCameraMoveBottomRight;
extern NSString* const LCCameraStop;
extern NSString* const LCCameraReset;

@interface FoscamCGIController : NSObject

- (id)initWithCGIPath:(NSString *)cgiPath username:(NSString *)username password:(NSString *)password;

// IR camera
- (void)setIRMode:(NSString *)mode;
- (void)setIR:(BOOL)mode;

// Camera movements
- (void)cameraMove:(NSString *)direction;
- (void)cameraMoveStop;

@end
