//
//  CameraViewController.h
//  LiluCam
//
//  Created by Takashi Okamoto on 12/14/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraViewController : UIViewController <UIScrollViewDelegate>

- (IBAction)toggleVideo:(id)sender;
- (IBAction)lightOn:(id)sender;
- (IBAction)lightOff:(id)sender;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *url;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end
