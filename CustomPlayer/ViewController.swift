//
//  ViewController.swift
//  CustomPlayer
//
//  Created by Ventuno Technologies on 08/01/19.
//  Copyright © 2019 Ventuno Technologies. All rights reserved.
//

import UIKit
import AVKit


protocol PlayerViewDelegate {
    func onPlayerEventLog(mPlayerView:PlayerView)
}

class PlayerView {
    
    private var mPlayer:AVPlayer?
    public var mPlayerContainer:UIView?
    
    private var mDispatchWorkItem:DispatchWorkItem?

    
    // Controls
    public var mPlayPauseButton:UIImageView?
    
    private var mPlayerLayer:AVPlayerLayer?
    
    public var delegate:PlayerViewDelegate?
    
    func loadPlayer()
    {
        //16:9
        //let mp4url = URL(string: "https://vtnpmds-a.akamaihd.net/669/17-10-2018/MMV1250715_TEN_640x360__H41QKIPR.mp4")
        
        //m3u8 without key
        let mp4url = URL(string: "http://cds.y9e7n6h3.hwcdn.net/videos/3044/03-09-2018/m3u8/Sivappu-Malli-ClipZ.m3u8")
        
        mPlayer = AVPlayer(url: mp4url!)
        mPlayerLayer = AVPlayerLayer(player: mPlayer!)
        
        //playerLayer.frame.size = CGSize(width: mPlayerContainer!.frame.width, height: mPlayerContainer!.frame.height)
        
       // playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
         mPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
       // playerLayer?.videoGravity = AVLayerVideoGravity.resize


        mPlayerLayer?.frame = mPlayerContainer!.bounds
        mPlayerLayer?.backgroundColor = UIColor.blue.cgColor
        self.mPlayerContainer?.layer.addSublayer(mPlayerLayer!)
        
        
        //Below line works
       // playerLayer.frame.size = CGSize(width: screenWidth ,height: (screenWidth*9/16) )
        
        
        //Show all Controls
        showControls()
        
        
        mPlayer?.play()
        
        pollPlayer()
    }
    
    func viewDidLayoutSubviews()
    {
        mPlayerLayer?.frame = mPlayerContainer!.bounds
    }
    
    func showControls()
    {
        mPlayPauseButton?.image = UIImage(named: "playButton")
        
    }
    
    func pollPlayer()
    {
        print("POLL PLAYER: \(String(describing: mPlayer?.status))")
        
        self.delegate?.onPlayerEventLog(mPlayerView: self)
        
        self.mDispatchWorkItem?.cancel()
        self.mDispatchWorkItem = DispatchWorkItem { self.pollPlayer() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.750, execute: mDispatchWorkItem!)
    }
    
    func play()
    {
        mPlayer?.play()
    }
    
    func pause()
    {
        mPlayer?.pause()
    }
    
    func movePlayHeadBySecs(_ mSecs:Int)
    {
        if let mPlayer = self.mPlayer {
            
            let mPlayHead:CMTime = CMTimeAdd(mPlayer.currentTime(), CMTimeMakeWithSeconds(Float64(mSecs), preferredTimescale: 1) )
            mPlayer.seek(to: mPlayHead)
        }
    }
    
    func getCurrentTime() -> Float64
    {
        if let mPlayer = self.mPlayer {
            return CMTimeGetSeconds(mPlayer.currentTime())
        }
        
        return 0.0
    }
    
    func getDuration() -> Float64
    {
        if let mPlayer = self.mPlayer {
            if let duration = mPlayer.currentItem?.asset.duration {
                return CMTimeGetSeconds(duration)
            }
        }
        
        return 0.0
    }
    
    func getStatus() -> String {
        
        if let mPlayer = self.mPlayer {
            switch mPlayer.status {
            case .failed:       return "FALIED"
            case .readyToPlay:  return "READY"
            case .unknown:      return "UNKNOWN"
            }
        }
        
        return "PREPARING"
        
    }
    
    
    
}
   



class ViewController: UIViewController {

    @IBOutlet weak var mPlayerContainer: UIView!
    
    private var mPlayerView:PlayerView?
    
    @IBOutlet weak var mTimeLabel: UILabel!
    @IBOutlet weak var mStatusLabel: UILabel!
    @IBOutlet weak var mExtraLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mPlayerView = PlayerView();
        mPlayerView?.mPlayerContainer = self.mPlayerContainer
        mPlayerView?.loadPlayer()
        mPlayerView?.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        mPlayerView?.viewDidLayoutSubviews()
    }
    
    
    @IBAction func mOnPlayClicked(_ sender: Any) {
        mPlayerView?.play()
    }
    

    @IBAction func mOnPauseClicked(_ sender: Any) {
        mPlayerView?.pause()
    }
    
    @IBAction func mOnFastForwardClicked(_ sender: Any) {
        mPlayerView?.movePlayHeadBySecs(15)
    }
    
    @IBAction func mOnFastBackwardClicked(_ sender: Any) {
        mPlayerView?.movePlayHeadBySecs(-15)
    }
    
    
    
    
}

extension ViewController : PlayerViewDelegate {
    func onPlayerEventLog(mPlayerView: PlayerView) {
        
        mTimeLabel?.text = "\(Int64(mPlayerView.getCurrentTime())) / \(Int64(mPlayerView.getDuration()))"
        
        mStatusLabel?.text = "\(mPlayerView.getStatus())"
    }
}
