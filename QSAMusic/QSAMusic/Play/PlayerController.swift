//
//  PlayerController.swift
//  QSAMusic
//
//  Created by 陈少文 on 17/5/5.
//  Copyright © 2017年 qqqssa. All rights reserved.
//

import UIKit
import SDWebImage

import AVFoundation

class PlayerController: NSObject, MusicManagerDelegate, QSAAudioPlayerDelegate {
    
    static let shared = PlayerController()
    
    private override init() {
        super.init()
        MusicManager.shared.delegate = self
        QSAAudioPlayer.shared.delegate = self
    }
    
    var playList = [NSDictionary]() //播放列表
    var playIndex: Int = 0          //当前播放标记
    var isPlaying = false
    var playTime: Int = 0
    var duration: Int = 0           //总时间
    
    func play(playList: [NSDictionary], index: Int) {
        self.playList = playList
        playIndex = index
        PlayPointView.shared.open(isList: true)
        PlayPointView.shared.openCallClosure = {
            self.play(index: index)
        }
        PlayView.shared().updataList(withData: playList)
    }
    
    // MARK: - MusicManager代理
    //准备播放, 更新播放界面
    func musicPrepare() {
        let music = playList[playIndex]
        if music["versions"] == nil {
            PlayView.shared().songLabel.text = music["title"] as? String
            PlayView.shared().author.text = music["artist"] as? String
        } else {
            if music["versions"] as! String != "" {
                PlayView.shared().songLabel.text = "\(music["title"] as! String)(\(music["versions"] as! String))"
            } else {
                PlayView.shared().songLabel.text = music["title"] as? String
            }
            PlayView.shared().author.text = music["author"] as? String
        }
        PlayView.shared().currentTime.text = "00:00"
        PlayView.shared().audioSlider.value = 0.0
        PlayView.shared().totalTime.text = "00:00"
        PlayView.shared().starImgV.image = UIImage(named: "QSAMusic_pc.png")
        PlayView.shared().playViewBackImageView.image = nil
        
        LrcTableView.shared().initLrc(withLrcStr: "")
        LrcTableView.shared().updateLrc(withCurrentTime: "00:00")
    }
    
    //准备完毕
    func music(createComplete music: NSMutableDictionary) {
        if music["version"] as! String != "" {
            PlayView.shared().songLabel.text = "\(music["songName"] as! String)(\(music["version"] as! String))"
        } else {
            PlayView.shared().songLabel.text = music["songName"] as? String
        }
        PlayView.shared().author.text = music["artistName"] as? String
        PlayView.shared().currentTime.text = "00:00"
        PlayView.shared().audioSlider.value = 0.0
        PlayView.shared().totalTime.text = String(format: "%02ld:%02ld", music["time"] as! Int / 60, music["time"] as! Int % 60)
        self.duration = music["time"] as! Int
        LrcTableView.shared().initLrc(withLrcURL: music["lrcLink"] as! String)
        let sdManager = SDWebImageManager.shared()
        
        var urlStr = music["songPicBig"] as! String
        urlStr = urlStr.replacingOccurrences(of: "w_150", with: "w_414")
        
        let url = URL(string: urlStr)
        sdManager?.downloadImage(with: url, options: [], progress: { (receivedSize, expectedSize) in
        }, completed: { (image, errer, _, _, imageURL) in
            PlayView.shared().starImgV.image = image
            PlayView.shared().playViewBackImageView.image = image?.blur(with: UIColor.black)
            QSMusicRemoteEvent.shared().addLockScreenView(withTitle: "\(music["songName"] as! String)", time: String(format: "%ld", Int(music["time"] as! NSNumber)), author: "\(music["artistName"] as! String)", image: image)
        })
    }
    
    func musicDownload(updateProgress progress: Double) {
        DispatchQueue.main.async(execute: {
            PlayView.shared().progressView.progress = Float(progress)
        })
    }
    
    func musicDownloadFail(error: Int) {
//        if error == -1009 && !isPlaying {
//            QSAKitFlashingPromptView.show(withMessage: "音乐加载失败, 请检查网络")
//            QSAAudioPlayer.shared.pause()
//        } else {
//            self.playNextIndex()
//        }
    }
    
    // MARK: - QSAAudioPlayer代理
    func player(updatePlayProgress playProgress: Float) {
        DispatchQueue.main.async(execute: {
            if !PlayView.shared().audioSlider.isTracking && !PlayView.shared().audioSlider.isTracking {
                PlayView.shared().audioSlider.value = playProgress
            }
        })
    }
    
    func player(updatePlayTime playTime: Int) {
        self.playTime = playTime
        let time = String(format: "%02ld", playTime / 60) + ":" + String(format: "%02ld", playTime % 60)
        DispatchQueue.main.async(execute: {
            PlayView.shared().currentTime.text = time
            LrcTableView.shared().updateLrc(withCurrentTime: time)
        })
    }
    
    func playerPlayEnd() {
        self.playNextIndex()
    }
    // MARK: -
    
    func changePlayMode() -> String {
        return "列表循环"
    }
    
    //上一曲
    func playPreviousIndex() {
        playIndex -= 1
        if playIndex  == -1 {
            playIndex = playList.count - 1
        }
        self.play(index: playIndex)
    }
    
    //下一曲
    func playNextIndex() {
        playIndex += 1
        if playIndex == playList.count {
            playIndex = 0
        }
        self.play(index: playIndex)
    }
    
    private func play(index: Int) {
        ListTableViewDelegate.shared().selectRow(index)
        isPlaying = true
    }
    
    func playAndPause() {
        if QSAAudioPlayer.shared.playing {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        QSAAudioPlayer.shared.play()
        isPlaying = true
        DispatchQueue.main.async(execute: {
            PlayView.shared().playButtonView.playButton.setImage(UIImage(named: "zantingduan3"), for: UIControlState.normal)
        })
    }
    
    func pause() {
        QSAAudioPlayer.shared.pause()
        isPlaying = false
        DispatchQueue.main.async(execute: {
            PlayView.shared().playButtonView.playButton.setImage(UIImage(named: "bf"), for: UIControlState.normal)
        })
    }
    
    func play(offset: Float) {
        MusicManager.shared.getMusic(playOffset: offset)
    }
    
    func play(time: Int) {
        MusicManager.shared.getMusic(playTime: Float(time))
    }
    
    //耳机拔出
    public func headphonePullOut() {
        pause()
        QSAAudioPlayer.shared.headphonePullOut()
    }
    
}
