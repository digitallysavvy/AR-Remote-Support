//
//  AgoraSupportAudienceViewController.swift
//  AR Remote Support
//
//  Created by digitallysavvy on 10/30/19.
//  Copyright © 2019 Agora.io. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

class ARSupportAudienceViewController: UIViewController, UIGestureRecognizerDelegate, AgoraRtcEngineDelegate {

    var touchStart: CGPoint!
    var touchPoints: [CGPoint]!
    let lineColor: CGColor = UIColor.gray.cgColor
    let bgColor: UIColor = .white
    
    var drawingView: UIView!
    var localVideoView: UIView!
    var micBtn: UIButton!
    
    let debug: Bool = true
    
    // Agora
    var agoraKit: AgoraRtcEngineKit!
    var channelName: String!
    
    // MARK: VC Events
    override func loadView() {
        super.loadView()
        createUI()
        setupGestures()
        
//        var frame = self.view.frame
//        frame.origin.x = self.view.center.x
//        frame.origin.y = self.view.center.y
//        self.view.frame = frame
        
        // Agora setup
        let appID = getValue(withKey: "AppID", within: "keys")
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        self.agoraKit.setClientRole(.audience)
        setupLocalVideo()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = self.bgColor
        self.view.isUserInteractionEnabled = true
        
        // Agora - join the channel
        let tokenString = getValue(withKey: "token", within: "keys")
        let token = (tokenString == "") ? nil : tokenString
        self.agoraKit.joinChannel(byToken: token, channelId: self.channelName, info: nil, uid: 0) { (channel, uintID, timeelapsed) in
            print("Successfully joined: \(channel), with \(uintID): \(timeelapsed) secongs ago")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // do something when the view has appeared
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setupGestures() {
        // pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Touch Capture
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       // get the initial touch event
        if let touch = touches.first {
            let position = touch.location(in: self.view)
            self.touchStart = position
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  position.x, y: position.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = self.lineColor
            guard let drawView = self.drawingView else { return }
            drawView.layer.addSublayer(layer)
            self.touchPoints = []
            if debug {
                 print(position)
            }
        }
    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//           let position = touch.location(in: self.view)
//            self.touchPoints.append(position)
//            print(position)
//            let layer = CAShapeLayer()
//            layer.path = UIBezierPath(roundedRect: CGRect(x:  position.x, y: position.y, width: 25, height: 25), cornerRadius: 50).cgPath
//            layer.fillColor = UIColor.white.cgColor
//            guard let drawView = self.drawingView else { return }
//            drawView.layer.addSublayer(layer)
//        }
//    }
    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self.view)
            // calculate touch movement relative to the superview
            guard let touchStart = self.touchStart else { return } // ignore accidental finger drags
            let pixelTranslation = CGPoint(x: touchStart.x + translation.x, y: touchStart.y + translation.y)
            
            // normalize the touch point to use view center as the reference point
//            let translationFromCenter = CGPoint(x: pixelTranslation.x - (0.5 * self.view.frame.width), y: pixelTranslation.y - (0.5 * self.view.frame.height))
            
//            let pixelTranslationFromCenter = CGPoint(x: 0.5 * self.view.frame.width + translationFromCenter.x, y: 0.5 * self.view.frame.height + translationFromCenter.y)
            
            self.touchPoints.append(pixelTranslation)
            
            // simple draw user touches
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: CGRect(x:  pixelTranslation.x, y: pixelTranslation.y, width: 25, height: 25), cornerRadius: 50).cgPath
            layer.fillColor = self.lineColor
            guard let drawView = self.drawingView else { return }
            drawView.layer.addSublayer(layer)
            
            if debug {
//                print(translationFromCenter)
                print(pixelTranslation)
               
            }
        }
        if gestureRecognizer.state == .ended {
            if let touchPointsList = self.touchPoints {
                print(touchPointsList)
                // push touch points list to AR View
                self.touchStart = nil // clear starting point
            }
        }
        
    }
    
    // MARK: UI
    func createUI() {
        
        // add remote video view
        let remoteView = UIView()
        remoteView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        remoteView.backgroundColor = UIColor.lightGray
        self.view.insertSubview(remoteView, at: 0)
        
        // view that the finger drawings will appear on
        let drawingView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.insertSubview(drawingView, at: 1)
        self.drawingView = drawingView
        
        // add local video view
        let localViewScale = self.view.frame.width * 0.33
        let localView = UIView()
        localView.frame = CGRect(x: self.view.frame.maxX - (localViewScale+17.5), y: self.view.frame.maxY - (localViewScale+25), width: localViewScale, height: localViewScale)
        localView.layer.cornerRadius = 25
        localView.layer.masksToBounds = true
        localView.backgroundColor = UIColor.darkGray
        self.view.insertSubview(localView, at: 2)
        self.localVideoView = localView
        
        // mute button
        let micBtn = UIButton()
        micBtn.frame = CGRect(x: self.view.frame.midX-37.5, y: self.view.frame.maxY-100, width: 75, height: 75)
        if let imageMicBtn = UIImage(named: "mic") {
            micBtn.setImage(imageMicBtn, for: .normal)
        } else {
            micBtn.setTitle("mute", for: .normal)
        }
        micBtn.addTarget(self, action: #selector(toggleMic), for: .touchDown)
        self.view.insertSubview(micBtn, at: 3)
        self.micBtn = micBtn
        
        //  back button
        let backBtn = UIButton()
        backBtn.frame = CGRect(x: self.view.frame.maxX-55, y: self.view.frame.minY + 20, width: 30, height: 30)
        backBtn.layer.cornerRadius = 10
        if let imageExitBtn = UIImage(named: "exit") {
            backBtn.setImage(imageExitBtn, for: .normal)
        } else {
            backBtn.setTitle("x", for: .normal)
        }
        backBtn.addTarget(self, action: #selector(popView), for: .touchUpInside)
        self.view.insertSubview(backBtn, at: 3)
        
    }
    
    // MARK: Button Events
    @IBAction func popView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleMic() {
        guard let activeMicImg = UIImage(named: "mic") else { return }
        guard let disabledMicImg = UIImage(named: "mute") else { return }
        if self.micBtn.imageView?.image == activeMicImg {
            print("disable active mic")
            self.micBtn.setImage(disabledMicImg, for: .normal)
        } else {
            print("enable mic")
            self.micBtn.setImage(activeMicImg, for: .normal)
        }
    }
    
    // MARK: Agora
    func setupLocalVideo() {
        guard let localVideoView = self.localVideoView else { return }
        self.agoraKit.enableVideo()
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = localVideoView
        videoCanvas.renderMode = .hidden
        // Set the local video view.
        self.agoraKit.setupLocalVideo(videoCanvas)
        
        guard let videoView = localVideoView.subviews.first else { return }
        videoView.layer.cornerRadius = 25
    }

}
