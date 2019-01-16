//
//  ViewController.swift
//  CustomPlayer
//
//  Created by Ventuno Technologies on 08/01/19.
//  Copyright © 2019 Ventuno Technologies. All rights reserved.
//



import UIKit
import AVKit
import MediaPlayer
import GoogleCast

protocol VtnPlayerViewDelegate {
    func onPlayerEventLog(mPlayerView:VtnPlayerView)
}

class VtnPlayerView {
    
    private var mPlayer:AVPlayer?
    public var mPlayerContainer:UIView?
    public var mPlayerAsset:AVAsset?
    private var mDispatchWorkItem:DispatchWorkItem?
    
    // Controls
    public var mPlayPauseButton:UIImageView?
    
  
    private var mPlayerItem: AVPlayerItem?
    private var mPlayerLayer:AVPlayerLayer?
    
    public var delegate:VtnPlayerViewDelegate?
    
    var observers:[NSKeyValueObservation]? = [NSKeyValueObservation]()
    private var mSelectedSubtitleLang:String?
    
    
    func loadPlayer()
    {
        //cast application id: 3C048DDC
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
       
        // Casting
        mPlayer?.allowsExternalPlayback=true
        
        
        
        mPlayerLayer = AVPlayerLayer(player: mPlayer!)
        
        //playerLayer.frame.size = CGSize(width: mPlayerContainer!.frame.width, height: mPlayerContainer!.frame.height)
        
       // playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
         mPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
       // playerLayer?.videoGravity = AVLayerVideoGravity.resize

        mPlayerLayer?.frame = mPlayerContainer!.bounds
        mPlayerLayer?.backgroundColor = UIColor.blue.cgColor
        self.mPlayerContainer?.layer.addSublayer(mPlayerLayer!)
        
        if let mPlayerContainer = self.mPlayerContainer {
            let myVolumeView = MPVolumeView(frame: mPlayerContainer.bounds)
            myVolumeView.showsVolumeSlider = false
            myVolumeView.showsRouteButton = true
            
            self.mPlayerContainer?.addSubview(myVolumeView)
        }
        
        //Below line works
       // playerLayer.frame.size = CGSize(width: screenWidth ,height: (screenWidth*9/16) )
        
        
        //Show all Controls
        showControls()
        
        
        mPlayer?.play()
        
        //Changing Quality
        mPlayerItem?.preferredPeakBitRate = false ? (512+1) : 0
        
        
        
        if let mPlayerAsset = self.mPlayerAsset, let mPlayerItem = self.mPlayerItem {
            for characteristic in mPlayerAsset.availableMediaCharacteristicsWithMediaSelectionOptions {
                print("\(characteristic)")
                
                // Retrieve the AVMediaSelectionGroup for the specified characteristic.
                if let group = mPlayerAsset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
                    // Print its options.
                    for option in group.options {
                        var logStr = "META "
                        logStr += ", " + "\(option.displayName)"
                        logStr += ", " + "\(option.locale?.languageCode ?? "UNKNOWN")"
                        logStr += ", " + "\(option.isPlayable)"
                        logStr += ", " + "\(option.mediaType.rawValue)"
                        logStr += ", " + "\(option.extendedLanguageTag ?? "ELT")"
                       
                        print(logStr)
                    }
                }
            }
            
            if let group = mPlayerAsset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
                selectSubtitle("en-EN")

                //Change subtitle text properties
                if let kCMTextMarkupAttribute_RelativeFontSize = kCMTextMarkupAttribute_RelativeFontSize as? String, let kCMTextMarkupAttribute_ForegroundColorARGB = kCMTextMarkupAttribute_ForegroundColorARGB as? String {
                    if let rule:AVTextStyleRule = AVTextStyleRule(textMarkupAttributes: [kCMTextMarkupAttribute_RelativeFontSize: 200, kCMTextMarkupAttribute_ForegroundColorARGB: [1, 1, 0, 0]]) {
                        mPlayerItem.textStyleRules = [rule]
                    }
                }
            }
        }
        
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
    
    func selectSubtitle(_ subtitleLang:String)
    {
        if let mPlayerAsset = self.mPlayerAsset, let mPlayerItem = self.mPlayerItem {
            if let group = mPlayerAsset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
                self.mSelectedSubtitleLang = subtitleLang
                let locale = Locale(identifier: subtitleLang)
                let options =
                    AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
                if let option = options.first {
                    // Select Spanish-language subtitle option
                    mPlayerItem.select(option, in: group)
                }
            }
        }
    }
    
    func setVideoQuality(_ mQuality:Double)
    {
//
//        let url = "http://cds.y9e7n6h3.hwcdn.net/videos/3044/03-09-2018/m3u8/Sivappu-Malli-ClipZ.m3u8"
//        //let url = "http://cdnbakmi.kaltura.com/p/243342/sp/24334200/playManifest/entryId/0_uka1msg4/flavorIds/1_vqhfu6uy,1_80sohj7p/format/applehttp/protocol/http/a.m3u8"
//
//
//        //m3u8 without ke
//        let m3u8url = URL(string: url)
//
//        mPlayerItem = AVPlayerItem(url: m3u8url!)
//
//
//
//        mPlayerItem = AVPlayerItem(asset: mPlayerAsset!)
//        
//        mPlayer = AVPlayer(playerItem: mPlayerItem )
//        mPlayerLayer = AVPlayerLayer(player: mPlayer!)
//
          mPlayerItem?.preferredPeakBitRate = mQuality>0 ? (mQuality+1) : 0
        
    }
    
    func toggleSubtitleVisibility(_ mShow:Bool)
    {
        
        if(mShow) {
            if let mSelectedSubtitleLang = self.mSelectedSubtitleLang {
                selectSubtitle(mSelectedSubtitleLang)
            }
        }
        else {
            if let group = mPlayer?.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
                mPlayer?.currentItem?.select(nil, in: group)
            }
        }
    }
    
}
   



class ViewController: UIViewController {

    @IBOutlet weak var mPlayerContainer: UIView!
    
    private var mPlayerView:VtnPlayerView?
   
    
    @IBOutlet weak var mTimeLabel: UILabel!
    @IBOutlet weak var mStatusLabel: UILabel!
    @IBOutlet weak var mExtraLabel: UILabel!
    
  
    private var sessionManager: GCKSessionManager!
    private var castSession: GCKCastSession?
    private var castMediaController: GCKUIMediaController!
    private var volumeController: GCKUIDeviceVolumeController!
    
    
    @IBAction func mCastButton(_ sender: Any) {
        
        
        
        let gcast_url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
        guard let mediaURL = gcast_url else {
            print("invalid mediaURL")
            return
        }
        
        let metadata = GCKMediaMetadata()
        metadata.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle)
        metadata.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger than " +
            "himself. When one sunny day three rodents rudely harass him, something " +
            "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
            "tradition he prepares the nasty rodents a comical revenge.",
                           forKey: kGCKMetadataKeySubtitle)
        metadata.addImage(GCKImage(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
                                   width: 480,
                                   height: 360))
        
        
        
       // let randomTimeIntervalThatYouShouldntUseIRL = TimeInterval(980)
        

        
        let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaURL)
        mediaInfoBuilder.streamType = GCKMediaStreamType.none;
        mediaInfoBuilder.contentType = "video/mp4"
        mediaInfoBuilder.metadata = metadata;
        
        let mediaInformation:GCKMediaInformation = mediaInfoBuilder.build()
        
        
        let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession
        
        if (castSession != nil) {
            print("castSession wasn't nil, time to load the media!")
            castSession?.remoteMediaClient?.loadMedia(mediaInformation)
        }
        
        castSession?.remoteMediaClient?.play()
        
    }
    
  

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mPlayerView = VtnPlayerView();
        mPlayerView?.mPlayerContainer = self.mPlayerContainer
        mPlayerView?.loadPlayer()
        mPlayerView?.delegate = self
        
        
        
        
        // Google Cast
       
        self.sessionManager = GCKCastContext.sharedInstance().sessionManager
        self.castMediaController = GCKUIMediaController()
        self.volumeController = GCKUIDeviceVolumeController()
        
        
       
        
        //Media Properties
        
                let metadata = GCKMediaMetadata()
                metadata.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle)
                metadata.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger than " +
                    "himself. When one sunny day three rodents rudely harass him, something " +
                    "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
                    "tradition he prepares the nasty rodents a comical revenge.",
                                   forKey: kGCKMetadataKeySubtitle)
                metadata.addImage(GCKImage(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
                                           width: 480,
                                           height: 360))
        
        
                //Load Media
        
                let gcast_url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
                guard let mediaURL = gcast_url else {
                    print("invalid mediaURL")
                    return
                }
        
                let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaURL)
                mediaInfoBuilder.streamType = GCKMediaStreamType.none;
                mediaInfoBuilder.contentType = "video/mp4"
                mediaInfoBuilder.metadata = metadata;
        
        
        let mediaInformation:GCKMediaInformation = mediaInfoBuilder.build()
        
        

        castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession
        if (castSession != nil) {
            print("castSession wasn't nil, time to load the media!")
             castSession?.remoteMediaClient?.loadMedia(mediaInformation)
        }
        else{
            print("No Session")
        }
        
        
        
//                guard let mediaInfo = mediaInformation else {
//                    print("invalid mediaInformation")
//                    return
//                }
        
        
        
//                if let request = sessionManager.currentSession?.remoteMediaClient?.loadMedia(mediaInformation) {
//                    request.delegate = self as! GCKRequestDelegate
//                }

        
      
       
       
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
    
    
    // Subtitle Buttons
    
    
    @IBAction func mOnSubtitle(_ sender: Any) {
        mPlayerView?.toggleSubtitleVisibility(true)
    }
    
    
    @IBAction func mOffSubtitle(_ sender: Any) {
        mPlayerView?.toggleSubtitleVisibility(false)
    }
    
    @IBAction func mSubtileEnglish(_ sender: Any) {
        mPlayerView?.selectSubtitle("en-EN")
    }
    
    
    @IBAction func mSubtitleTamil(_ sender: Any) {
        mPlayerView?.selectSubtitle("fr-FR")
    }
    
    @IBAction func mOn720p(_ sender: Any) {
        mPlayerView?.setVideoQuality(1020)
    }
    
    @IBAction func mOn480p(_ sender: Any) {
        mPlayerView?.setVideoQuality(512)
    }
    
    @IBAction func mOn256p(_ sender: Any) {
        mPlayerView?.setVideoQuality(256)
    }
    @IBAction func mOnResetToAuto(_ sender: Any) {
//mPlayerView?.setVideoQuality(0)
        
    }
    
    
}

extension ViewController : VtnPlayerViewDelegate {
    func onPlayerEventLog(mPlayerView: VtnPlayerView) {
        
        mTimeLabel?.text = "\(Int64(mPlayerView.getCurrentTime())) / \(Int64(mPlayerView.getDuration()))"
        
        mStatusLabel?.text = "\(mPlayerView.getStatus())"
        
        mExtraLabel?.text = "\(mPlayerView.getCurrentVideoQuality())"
     
    }
}

