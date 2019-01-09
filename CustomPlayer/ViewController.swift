//
//  ViewController.swift
//  CustomPlayer
//
//  Created by Ventuno Technologies on 08/01/19.
//  Copyright © 2019 Ventuno Technologies. All rights reserved.
//

//Git Change name check

import UIKit
import AVKit


protocol VtnPlayerViewDelegate {
    func onPlayerEventLog(mPlayerView:VtnPlayerView)
}

class VtnPlayerView {
    
    private var mPlayer:AVPlayer?
    public var mPlayerContainer:UIView?
    
    private var mDispatchWorkItem:DispatchWorkItem?

    
    // Controls
    public var mPlayPauseButton:UIImageView?
    
    private var mPlayerAsset:AVURLAsset?
    private var mPlayerItem: AVPlayerItem?
    private var mPlayerLayer:AVPlayerLayer?
    
    public var delegate:VtnPlayerViewDelegate?
    
    var observers:[NSKeyValueObservation]? = [NSKeyValueObservation]()
    
    
    func loadPlayer()
    {
        //16:9 mp4url
        //let mp4url = URL(string: "https://vtnpmds-a.akamaihd.net/669/17-10-2018/MMV1250715_TEN_640x360__H41QKIPR.mp4")
        
        //let url = "http://cds.y9e7n6h3.hwcdn.net/videos/3044/03-09-2018/m3u8/Sivappu-Malli-ClipZ.m3u8"
        let url = "http://cdnbakmi.kaltura.com/p/243342/sp/24334200/playManifest/entryId/0_uka1msg4/flavorIds/1_vqhfu6uy,1_80sohj7p/format/applehttp/protocol/http/a.m3u8"
        
        
        //m3u8 without key
        let m3u8url = URL(string: url)
        
        mPlayerAsset = AVURLAsset(url: m3u8url!)
        
        //mPlayerItem = AVPlayerItem(url: m3u8url!)
        mPlayerItem = AVPlayerItem(asset: mPlayerAsset!)
        
        
        mPlayer = AVPlayer(playerItem: mPlayerItem )
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
        
        //Changing Quality
        mPlayerItem?.preferredPeakBitRate = false ? (512+1) : 0
        
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
        //print("POLL PLAYER: \(String(describing: mPlayer?.status))")
        
        var logStr:String = "";
        logStr += getStatus()
        
        logStr += ", " + "\(self.mPlayer?.currentItem?.preferredPeakBitRate ?? 0)"
        if let presentationSize = self.mPlayer?.currentItem?.presentationSize {
            logStr += ", presentationSize: " + "\(presentationSize.width)x\(presentationSize.height)"
        }
        
        //let accessLog = self.mPlayerItem?.accessLog()
        
        //logStr += ", " + "\(accessLog.debugDescription)"
        //logStr += ", " + "\(accessLog?.description)"
        
        if let tracks = self.mPlayer?.currentItem?.tracks {
            for track in tracks {
                logStr += ", " + "\(track.isEnabled)"
                logStr += ", " + "\(track.currentVideoFrameRate)"
                
                if let assetTrack = track.assetTrack {
                    logStr += ", " + "\(assetTrack.trackID)"
                    logStr += ", " + "\(assetTrack.mediaType.rawValue)"
                    logStr += ", " + "\(assetTrack.estimatedDataRate)"
                    logStr += ", " + "\(assetTrack.languageCode ?? "NIL")"
                    
                    for metadata in assetTrack.metadata {
                        logStr += ", " + "\(metadata.stringValue ?? "")"
                        logStr += ", " + "\(metadata.numberValue ?? 0)"
                    }
                }
            }
        }
        
        
        print(logStr)

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
    
    func getCurrentVideoQuality() -> String
    {
        let bitrate = mPlayer?.currentItem?.preferredPeakBitRate ?? 0
        
        return bitrate<=0 ? "Auto" : "\((Int64(bitrate)-1))p"
    }
    
}
   



class ViewController: UIViewController {

    @IBOutlet weak var mPlayerContainer: UIView!
    
    private var mPlayerView:VtnPlayerView?
    
    @IBOutlet weak var mTimeLabel: UILabel!
    @IBOutlet weak var mStatusLabel: UILabel!
    @IBOutlet weak var mExtraLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mPlayerView = VtnPlayerView();
        mPlayerView?.mPlayerContainer = self.mPlayerContainer
        mPlayerView?.loadPlayer()
        mPlayerView?.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        mPlayerView?.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
         // Network Check
        if(Reachability.isConnectedToNetwork()){
            print("Network Available")
        }
        else
        {
            print("Network Not Available")
        }

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

extension ViewController : VtnPlayerViewDelegate {
    func onPlayerEventLog(mPlayerView: VtnPlayerView) {
        
        mTimeLabel?.text = "\(Int64(mPlayerView.getCurrentTime())) / \(Int64(mPlayerView.getDuration()))"
        
        mStatusLabel?.text = "\(mPlayerView.getStatus())"
        
        mExtraLabel?.text = "\(mPlayerView.getCurrentVideoQuality())"
     
    }
}

