//
//  QSAAudioPlayer.swift
//  EEEEE
//
//  Created by 陈少文 on 17/5/11.
//  Copyright © 2017年 qqqssa. All rights reserved.
//

import UIKit
import AVFoundation

open class QSAAudioPlayer: NSObject, UITableViewDelegate {
    
    // MARK: - private variables
    private var engine = AVAudioEngine()                   //engine
    private var internalAudioFile: AVAudioFile?            //播放文件
    private var internalPlayer: AVAudioPlayerNode?         //播放器
    private var defaultSampleRate: Double = 44100.0        //默认采样率
    private var defaultChannels: AVAudioChannelCount = 2   //默认通道
    private var timer: DispatchSourceTimer?                //读取播放进度的定时器
    private var eq: AVAudioUnitEQ?                         //均衡器
    private var startTime: Double = 0                      //开始播放的时间
    
    // MARK: - open variables
    open var delegate: QSAAudioPlayerDelegate?
    open var playing = false
    
    // MARK: - sharedInstance
    open static let shared = QSAAudioPlayer()
    
    private override init() {
        super.init()
        startEngine()
    }
    
    // MARK: - engine设置
    ///将节点连接到engine上, 并启动engine
    private func startEngine() {
        let defaultFormat = AVAudioFormat(standardFormatWithSampleRate: defaultSampleRate, channels: defaultChannels)
        connectNode(format: defaultFormat)
        if !engine.isRunning {
            do {
                try engine.start()
            } catch let error as NSError {
                QSALog("couldn't start engine, Error: \(error)")
            }
        }
    }
    
    ///连接节点
    private func connectNode(format: AVAudioFormat) {
        //初始化eq均衡器, frequency数值, 参考qq音乐播放器
        eq = AVAudioUnitEQ(numberOfBands: 10)
        let frequencys = [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]
        for i in 0...9 {
            let filterParams = eq?.bands[i]
            filterParams?.bandwidth = 1.0
            filterParams?.bypass = false
            filterParams?.frequency = Float(frequencys[i])
        }
        
        internalPlayer = AVAudioPlayerNode()
        
        engine.attach(eq!)
        engine.attach(internalPlayer!)
        engine.connect(internalPlayer!, to: eq!, format: format)
        engine.connect(eq!, to: engine.mainMixerNode, format: format)
    }
    
    ///重新连接所有节点
    private func reconnectNode(format: AVAudioFormat) {
        engine.detach(eq!)
        engine.detach(internalPlayer!)
        connectNode(format: format)
    }
    
    // MARK: - player操作
    ///播放器暂停后同时要暂停engine, 这样锁屏界面才会暂停, 但此时锁屏界面的时间并没有停止, 再次恢复播放的时候, 时间会直接跳过暂停的时长. 百度音乐盒也有同样的问题, 只是它做了处理, 再次刷新了时间
    public func playAndPause() {
        if !playing {
            if !engine.isRunning {
                do {
                    try engine.start()
                } catch let error as NSError {
                    QSALog("couldn't start engine, Error: \(error)")
                }
            }
            internalPlayer?.play()
            playing = true
            timer?.resume()
        } else {
            internalPlayer?.pause()
            if engine.isRunning {
                engine.pause()
            }
            playing = false
            timer?.suspend()
        }
    }
    
    public func prepare() {
        playing = false
        internalPlayer?.stop()
        timer?.cancel()
    }
    
    public func play(startTime: Int = 0, endTime: Int, path: String) {
        self.startTime = Double(startTime)

        do {
            internalAudioFile = try AVAudioFile(forReading: URL(string: path)!)
        } catch let error as NSError {
            QSALog("不能打开文件, Error: \(error)")
        }
        
        if (internalAudioFile?.length)! > 0 {
            
            ///先判断当前播放文件的采样率和通道是否和engine的设置相同, 如果不同, 重新设置engine.(比如此时engine的采样率为:44000, 而文件的采样率为:48000, 那么播放的速度就是44000 / 48000 < 1, 音乐听上去就是慢放, 反之就是快放. 这是使用第三方库AudioKit的播放器AKAudioPlayer发现的)
            if internalAudioFile?.fileFormat.sampleRate != defaultSampleRate || internalAudioFile?.fileFormat.channelCount != defaultChannels {
                reconnectNode(format: (internalAudioFile?.fileFormat)!)
            }
            
            ///为播放器准备文件
            ///此处有个坑, 当audio文件播放完毕后, 如果调用completionHandler播放完成函数, 那么再调用internalPlayer?.stop()就会崩溃, 如果不调用internalPlayer?.stop(), 时间就无法重置. 所以此处不设置播放完成函数, 用其他方法实现播放完成回调
            internalPlayer?.scheduleFile(internalAudioFile!, at: nil, completionHandler: nil)
            
            ///定时器读取播放进度
            timer = DispatchSource.makeTimerSource(flags: [], queue:DispatchQueue.main)
            let timer_s = endTime - startTime
            timer?.scheduleRepeating(deadline: .now(), interval: .seconds(1) ,leeway:.milliseconds(timer_s))
            timer?.setEventHandler {
                let s = self.currentTime()
                if Int(lround(s)) == endTime + 1 {
                    self.internalPlayer?.pause()
                    self.delegate?.playerPlayEnd!()
                }
                self.delegate?.player!(updatePlayTime: Int(lround(s)))
                self.delegate?.player!(updatePlayProgress: Float(Float(s) / Float(endTime)))
            }
            
            ///play
            playAndPause()
        } else {
            QSALog("音乐文件加载失败")
            QSAKitFlashingPromptView.show(withMessage: "音乐文件加载失败")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: { 
                self.delegate?.playerPlayEnd!()
            })
        }
    }
    
    private func currentTime() -> Double {
        if let nodeTime = internalPlayer?.lastRenderTime,
            let playerTime = internalPlayer?.playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate + startTime
        }
        return 0.0
    }
    
    //MARK: - eq
    public func updateEQ(gains: [String]) {
        for i in 0...9 {
            let filterParams = eq?.bands[i]
            filterParams?.gain = Float(gains[i])!
        }
    }
    
    public func updateEQ(BandIndex: Int, gain: Float) {
        let filterParams = eq?.bands[BandIndex]
        filterParams?.gain = gain
    }
}

//MARK: - QSAAudioPlayerDelegate
@objc public protocol QSAAudioPlayerDelegate: NSObjectProtocol {
    
    @objc optional func player(updatePlayTime playTime: Int)
    
    @objc optional func player(updatePlayProgress playProgress: Float)
    
    @objc optional func playerPlayEnd()
}
