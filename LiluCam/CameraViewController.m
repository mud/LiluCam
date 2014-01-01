//
//  CameraViewController.m
//  LiluCam
//
//  Created by Takashi Okamoto on 12/14/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import "CameraViewController.h"
#import "FFFrameExtractor.h"
#import "FoscamCGIController.h"

#define CGI_PROXY @"http://10.0.1.11:88/cgi-bin/CGIProxy.fcgi"

@interface CameraViewController () <FFFrameExtractorDelegate> {
    FFFrameExtractor *frameExtractor;
    UIPinchGestureRecognizer *pinchGesture;
    FoscamCGIController *cameraController;
    NSTimer *playTimer;
    
    UITapGestureRecognizer *tapGesture;
}

- (NSString *)rtspURL;
- (NSString *)cgiURL;
- (void)displayNextFrame:(NSTimer *)timer;
- (void)cancelDisplayNextFrame;

@end

@implementation CameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    cameraController = [[FoscamCGIController alloc] initWithCGIPath:self.cgiURL username:self.username password:self.password];
    frameExtractor = [[FFFrameExtractor alloc] initWithInputPath:self.rtspURL];
    
    // create tap gesture
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.scrollView addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"Camera View did Disappear");
    [self cancelDisplayNextFrame];
    [frameExtractor stop];
    [super viewDidDisappear:animated];
}

- (IBAction)toggleVideo:(id)sender
{
    if ([self.playButton.title isEqualToString:@"Play"]) {
        self.playButton.title = @"Stop";
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
            [frameExtractor start];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                // start image display
                playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
                                                             target:self
                                                           selector:@selector(displayNextFrame:)
                                                           userInfo:nil
                                                            repeats:YES];
            });
        });
    } else {
        self.playButton.title = @"Play";
        [self cancelDisplayNextFrame];
    }
    
}

- (IBAction)lightOn:(id)sender
{
    [cameraController setIR:YES];
}

- (IBAction)lightOff:(id)sender
{
    [cameraController setIR:NO];
}

- (void)tapped:(UITapGestureRecognizer *)gesture
{
    CGRect toolbarFrame = self.toolbar.frame;
    if (self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        toolbarFrame.origin.y -= 44;
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        toolbarFrame.origin.y += 44;
    }
    
    // animate toolbar hide
    [UIView animateWithDuration:.3
                     animations:^(void){
                         self.toolbar.frame = toolbarFrame;
                     }];
}


#pragma mark - FFFrameExtractorDelegate

- (void)updateWithCurrentUIImage:(UIImage *)image
{
    if (image != nil) {
        self.imageView.image = image;
    }
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


#pragma mark - Private Methods

- (NSString *)rtspURL
{
    return [NSString stringWithFormat:@"rtsp://%@:%@@%@/videoMain", self.username, self.password, self.url];
}

- (NSString *)cgiURL
{
    return [NSString stringWithFormat:@"%@/cgi-bin/CGIProxy.fcgi", self.url];
}

- (void)displayNextFrame:(NSTimer *)timer
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        if (frameExtractor.delegate == nil) {
            frameExtractor.delegate = self;
        }
        [frameExtractor processNextFrame];
    }
}

- (void)cancelDisplayNextFrame
{
    frameExtractor.delegate = nil;
    [playTimer invalidate];
}

@end
