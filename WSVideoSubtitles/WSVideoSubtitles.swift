//
//  WSVideoSubtitles.swift
//  WSVideoSubtitles
//
//  Created by 田向阳 on 2018/12/11.
//  Copyright © 2018 田向阳. All rights reserved.
//

import UIKit
import AVFoundation

class WSVideoSubtitles {

    var mutableComposition = AVMutableComposition()
    var mutableVideoComposition = AVMutableVideoComposition()
    var subTitlesLayer: CALayer?
    
    var outputURL: String? {
        if let cachePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first {
            return cachePath + "/output.mp4"
        }
        return nil
    }
    
    public func addSubTitles(videoPath: String, _ complete: ((_ finish: Bool)->())?) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
        guard let videoTrack = asset.tracks(withMediaType: .video).first, let audioTrack = asset.tracks(withMediaType: .audio).first, let `subTitlesLayer` = subTitlesLayer, let `outputURL` = outputURL else {
            complete?(false)
            return
        }
        let insertionPoint = CMTime.zero
        do {
            let videoCompisitionTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let audioCompisitionTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            try videoCompisitionTrack?.insertTimeRange(CMTimeRangeMake(start:insertionPoint, duration: asset.duration), of: videoTrack, at: insertionPoint)
            try audioCompisitionTrack?.insertTimeRange(CMTimeRangeMake(start:insertionPoint, duration: asset.duration), of: audioTrack, at: insertionPoint)
            
            self.mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30) // 30 fps
            self.mutableVideoComposition.renderSize = videoTrack.naturalSize
            let passThroughInstruction = AVMutableVideoCompositionInstruction()
            passThroughInstruction.timeRange = CMTimeRangeMake(start: insertionPoint, duration: mutableComposition.duration)
            if let aVideoTrack = self.mutableComposition.tracks(withMediaType: .video).first{
                let passThroughLayer = AVMutableVideoCompositionLayerInstruction.init(assetTrack: aVideoTrack)
                passThroughInstruction.layerInstructions = [passThroughLayer]
                self.mutableVideoComposition.instructions = [passThroughInstruction]
            }
            let videoSize = self.mutableVideoComposition.renderSize
            let exportLayer = subTitlesLayer
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(exportLayer)
            self.mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            WSAVExportMediaFile.expertMedia(isVideo: true, path: outputURL, composition: self.mutableComposition, videoCompisition: mutableVideoComposition) { (finish) in
                complete?(finish)
            }
        }catch {
            complete?(false)
        }
    }
    
    public class func getVideoSize(path: String)-> CGSize {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let windowSize = UIScreen.main.bounds.size
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return CGSize(width: windowSize.width, height: windowSize.height)
        }
        let videoSize = videoTrack.naturalSize
        return videoSize
    }
    
    func test() -> CALayer{
            // 视频的显示大小

        let waterMarkImage = UIImage(named: "mt_videoWatermark")!
        let videoSize = self.mutableVideoComposition.renderSize
        let dataLayerSize = videoSize
        let scale = CGFloat(videoSize.height / videoSize.width)
        var Vwidth = CGFloat(0) ,Vheight =  CGFloat(0),Iwidth =  CGFloat(0),Iheight = CGFloat(0)
        if (scale >= 1) {
            Vheight = UIScreen.main.bounds.size.width
            Vwidth = Vheight / scale
        }else{
            Vwidth = UIScreen.main.bounds.size.width
            Vheight = Vwidth * scale;
        }
        let Wscale = dataLayerSize.width / Vwidth
        let Hscale = dataLayerSize.height /  Vheight
        Iwidth = (waterMarkImage.size.width + 15) * Wscale
        Iheight = (waterMarkImage.size.height + 15) * Hscale
        // 水印
        let waterMarkLayer = CALayer()
        waterMarkLayer.contents = waterMarkImage.cgImage ;
        waterMarkLayer.frame = CGRect(x: dataLayerSize.width - Iwidth,y: Iheight - 15 * 2 * Hscale,width: Iwidth  - 15 * Hscale,height: Iheight - 15 * Hscale)
        waterMarkLayer.opacity = 1
        return waterMarkLayer
    }
    
}

class WSAVExportMediaFile {
    
    public class func expertMedia(isVideo: Bool,path: String, composition: AVMutableComposition, videoCompisition: AVMutableVideoComposition,_ complete:((_ finish: Bool)->())?) {
        try? FileManager.default.removeItem(atPath: path)
        let exportSession = AVAssetExportSession(asset: composition, presetName: isVideo ? AVAssetExportPresetHighestQuality : AVAssetExportPresetAppleM4A)
        exportSession?.videoComposition = videoCompisition
        exportSession?.outputURL = URL(fileURLWithPath: path)
        exportSession?.outputFileType = isVideo ? AVFileType.mp4 : AVFileType.m4a
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession?.status {
                case .completed?:
                    if complete != nil{
                        complete!(true)
                    }
                    break
                default:
                    if complete != nil{
                        complete!(false)
                    }
                    print("导出失败：\(String(describing: exportSession?.error))")
                    break
                }
            }
        }
    }
}

extension CALayer {
    
    public class func createTextLayer(text: String,
                                      color: UIColor = UIColor.red,
                                      font: UIFont = UIFont.systemFont(ofSize: 50),
                                      startTime: Double,
                                      duration: Double,
                                      textRect: CGRect,
                                      viewSize: CGSize
                                      ) -> CALayer {
        let layer = CALayer()
        let titleLayer = CATextLayer()
        titleLayer.string = text
        titleLayer.font = font
        titleLayer.opacity = 1
        titleLayer.fontSize = font.pointSize
        titleLayer.alignmentMode = .left
        titleLayer.bounds = CGRect(x: 0,y: 0,width: textRect.size.width ,height: textRect.size.height + 10);
        titleLayer.foregroundColor = color.cgColor
        titleLayer.backgroundColor = UIColor.clear.cgColor
        
        let initAnimationDuration = 0.1
        let animationDuration = 0.15
        let animatedInStartTime = startTime + initAnimationDuration

        let startAnimation = CABasicAnimation(keyPath: "opacity")
        startAnimation.fromValue = 0.0
        startAnimation.toValue = 1.0
        startAnimation.isAdditive = false
        startAnimation.isRemovedOnCompletion = false
        startAnimation.beginTime = animatedInStartTime
        startAnimation.duration = animationDuration
        startAnimation.autoreverses = false
        startAnimation.fillMode = CAMediaTimingFillMode.both
        titleLayer.add(startAnimation, forKey: "inOpacity")
        
        let animatedEndStartTime = startTime + duration - animationDuration
        let endAnimation = CABasicAnimation(keyPath: "opacity")
        endAnimation.fromValue = 1.0
        endAnimation.toValue = 0
        endAnimation.isAdditive = false
        endAnimation.isRemovedOnCompletion = false
        endAnimation.beginTime = animatedEndStartTime
        endAnimation.duration = animationDuration
        endAnimation.autoreverses = false
        endAnimation.fillMode = CAMediaTimingFillMode.both
        layer.addSublayer(titleLayer)
        layer.add(endAnimation, forKey: "inOpacity")
 
        layer.position = CGPoint(x: textRect.origin.x + textRect.size.width/2,y: viewSize.height - textRect.size.height/2 - textRect.origin.y);
        return layer
    }
    
}

extension String {
    
    public func height(_ width: CGFloat, font: UIFont, lineBreakMode: NSLineBreakMode?) -> CGFloat {
        var attrib: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: font]
        if lineBreakMode != nil {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode!
            attrib.updateValue(paragraphStyle, forKey: NSAttributedString.Key.paragraphStyle)
        }
        let size = CGSize(width: width, height: CGFloat(Double.greatestFiniteMagnitude))
        return ceil((self as NSString).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attrib, context: nil).height)
    }
}
