//
//  StreamInfoViewController.m
//  LiluCam
//
//  Created by Takashi Okamoto on 12/29/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import "StreamInfoViewController.h"
#import "CameraViewController.h"

@interface StreamInfoViewController ()

@end

@implementation StreamInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *username = [defaults objectForKey:@"username"];
    if (username) {
        self.usernameField.text = username;
    }
    
    NSString *password = [defaults objectForKey:@"password"];
    if (password) {
        self.passwordField.text = password;
    }
    
    NSString *url = [defaults objectForKey:@"url"];
    if (url) {
        self.urlField.text = url;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitLogin:(id)sender
{
    if (self.usernameField.text.length == 0 || self.passwordField.text.length == 0 || self.urlField.text.length == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"You must specify all fields." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [av show];
    } else {
        [self performSegueWithIdentifier:@"cameraViewSegue" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"cameraViewSegue"]) {
        CameraViewController *destVC = (CameraViewController *)segue.destinationViewController;
        destVC.username = self.usernameField.text;
        destVC.password = self.passwordField.text;
        destVC.url = self.urlField.text;
        
        // save these for next time
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.usernameField.text forKey:@"username"];
        [defaults setObject:self.passwordField.text forKey:@"password"];
        [defaults setObject:self.urlField.text forKey:@"url"];
        [defaults synchronize];
    }
}

@end
