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

@interface CameraViewController () <FFFrameExtractorDelegate, UIGestureRecognizerDelegate> {
    FFFrameExtractor *frameExtractor;
    UIPinchGestureRecognizer *pinchGesture;
    FoscamCGIController *cameraController;
    NSTimer *playTimer;
    
    UITapGestureRecognizer *tapGesture;
    BOOL _navigationHidden;
    NSOperationQueue *opQueue;
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
    //tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [tapGesture requireGestureRecognizerToFail:self.scrollView.panGestureRecognizer];
    //[self.scrollView addGestureRecognizer:tapGesture];
    [self.scrollView addGestureRecognizer:tapGesture];
    _navigationHidden = NO;
    
    // specify background image
    UIImage *backgroundImage = [UIImage imageNamed:@"cam-background.png"];
    self.imageView.image = backgroundImage;
    
    // create opQueue
    opQueue = [[NSOperationQueue alloc] init];
    opQueue.maxConcurrentOperationCount = 1; // set to 1 to force everything to run on one thread
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
        
        // turn off dimming
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        [opQueue addOperationWithBlock:^(void){
            if ([frameExtractor start]) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    // start image display
                    playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
                                                                 target:self
                                                               selector:@selector(displayNextFrame:)
                                                               userInfo:nil
                                                                repeats:YES];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"FFFrameExtractor Error" message:@"Couldn't start frame. Try again." delegate:Nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                    self.playButton.title = @"Play";
                    [av show];
                });
            }
        }];
        
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
    CGRect navigationBarFrame = self.navigationController.navigationBar.frame;
    if (_navigationHidden) {
        navigationBarFrame.origin.y += 64;
        toolbarFrame.origin.y -= 44;
    } else {
        navigationBarFrame.origin.y -= 64;
        toolbarFrame.origin.y += 44;
    }
    
    // animate toolbar hide
    [UIView animateWithDuration:.3
                     animations:^(void){
                         self.navigationController.navigationBar.frame = navigationBarFrame;
                         self.toolbar.frame = toolbarFrame;
                     }
                     completion:^(BOOL finished){
                         _navigationHidden = !_navigationHidden;
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


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
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
        [opQueue addOperationWithBlock:^(void){
            if (frameExtractor.delegate == nil) {
                frameExtractor.delegate = self;
            }
            [frameExtractor processNextFrame];
        }];
    }
}

- (void)cancelDisplayNextFrame
{
    // turn off dimming
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    frameExtractor.delegate = nil;
    [playTimer invalidate];
    [opQueue cancelAllOperations];
    [opQueue addOperationWithBlock:^(void){
        [frameExtractor stop];
    }];
}

@end
