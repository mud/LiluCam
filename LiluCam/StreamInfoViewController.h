//
//  StreamInfoViewController.h
//  LiluCam
//
//  Created by Takashi Okamoto on 12/29/13.
//  Copyright (c) 2013 Takashi Okamoto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StreamInfoViewController : UIViewController

- (IBAction)submitLogin:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *urlField;
@property (weak, nonatomic) IBOutlet UITextField *cgiField;

@end
