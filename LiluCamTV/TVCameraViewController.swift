//
//  TVCameraViewController.swift
//  LiluCamTV
//
//  Created by Takashi Okamoto on 10/21/15.
//  Copyright © 2015 Takashi Okamoto. All rights reserved.
//

import UIKit

class TVCameraViewController: UIViewController, FFFrameExtractorDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    private var playing:Bool = false
    
    var username:String?
    var password:String?
    var urlPath:String?
    var cgiURLPath:String?
    
    var frameExtractor:FFFrameExtractor?
    var cameraController:FoscamCGIController?
    var playTimer:NSTimer?
    var opQueue:NSOperationQueue?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let username = defaults.objectForKey("username") {
            self.username = username as? String
        }
        
        if let password = defaults.objectForKey("password") {
            self.password = password as? String
        }
        
        if let url = defaults.objectForKey("url") {
            self.urlPath = url as? String
        }
        
        cameraController = FoscamCGIController.init(CGIPath: self.cgiURL(), username: self.username!, password: self.password!)
        if let url = self.rtspURL() {
            frameExtractor = FFFrameExtractor.init(inputPath: url)
            frameExtractor?.imageOrientation = UIImageOrientation.Up
        }
        if let backgroundImage:UIImage? = UIImage.init(named: "cam-background.png") {
            self.imageView.image = backgroundImage
        }
        opQueue = NSOperationQueue.init()
        opQueue?.maxConcurrentOperationCount = 1
        
        // Add notifications
//        [[NSNotificationCenter defaultCenter] addObserver: self
//            selector: @selector(handleEnteredBackground:)
//        name: UIApplicationDidEnterBackgroundNotification
//        object: nil];

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleEnteredBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleReactivate", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        print("viewDidDisappear was called")
        self.cancelDisplayNextFrame()
        frameExtractor?.stop()
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Play Methods
    
    func play() {
        if !playing {
            playing = true
            
            UIApplication.sharedApplication().idleTimerDisabled = true
            
            opQueue?.addOperationWithBlock({ () -> Void in
                if let frame = self.frameExtractor {
                    if frame.start() {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.playTimer = NSTimer.scheduledTimerWithTimeInterval(1.0/30.0, target: self, selector: "displayNextFrame:", userInfo: nil, repeats: true)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                        })
                    }
                }
            })
        }
    }
    
    func pause() {
        if playing {
            self.cancelDisplayNextFrame()
            playing = false
        }
    }
    
    func toggle() {
        if playing {
            pause()
        } else {
            play()
        }
    }
    
    
    // MARK: - FFFrameExtractorDelegate
    
    func updateWithCurrentUIImage(image: UIImage!) {
        if image != nil {
            self.imageView.image = image
        }
    }
    
    
    // MARK: - Private Methods
    
    func rtspURL() -> String? {
        if username == nil || password == nil || urlPath == nil {
            return nil
        }
        
        let standardUserDefaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if standardUserDefaults.boolForKey("wifi_preference") {
            return "rtsp://\(username!):\(password!)@\(urlPath!)/videoMain"
        }
        return "rtsp://\(username!):\(password!)@\(urlPath!)/videoSub"
    }
    
    func cgiURL() -> String {
        return "\(urlPath)/cgi-bin/CGIProxy.fcgi"
    }
    
    func displayNextFrame(timer: NSTimer) {
        if UIApplication.sharedApplication().applicationState == UIApplicationState.Active {
            opQueue?.addOperationWithBlock({ () -> Void in
                if self.frameExtractor!.delegate == nil {
                    self.frameExtractor!.delegate = self
                }
                self.frameExtractor!.processNextFrame()
            })
        }
    }

    func cancelDisplayNextFrame() {
        UIApplication.sharedApplication().idleTimerDisabled = false
        frameExtractor?.delegate = nil
        playTimer?.invalidate()
        opQueue?.cancelAllOperations()
        opQueue?.addOperationWithBlock({ () -> Void in
            self.frameExtractor?.stop()
        })
    }
    
    
    // MARK: - Notifications
    
    func handleEnteredBackground() {
        print("entered background")
        
        self.pause()
    }
    
    func handleReactivate() {
        print("reactivated")
        
        if  self.username == nil ||
            self.password == nil ||
            self.urlPath == nil {
                print("Need to specify username, password, url")
        } else {
            print("Yes, lets continue")
            self.play()
        }
    }
    
}

