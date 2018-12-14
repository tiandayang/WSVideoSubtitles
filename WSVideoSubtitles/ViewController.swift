//
//  ViewController.swift
//  WSVideoSubtitles
//
//  Created by 田向阳 on 2018/12/11.
//  Copyright © 2018 田向阳. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    var loadingView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    var videoSubTitlesTool = WSVideoSubtitles()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(loadingView)
        loadingView.frame = self.view.bounds
    }

    @IBAction func make(_ sender: Any) {
        loadingView.startAnimating()
        let startTime = Date().timeIntervalSince1970
        if let path = Bundle.main.path(forResource: "123", ofType: "MP4") {
            let subTitleLayer = CALayer()
            let subTitles = ["啊，啊~","哈哈哈","哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈哈213213123"]
            for (index,text) in subTitles.enumerated() {
                let font = UIFont.systemFont(ofSize: 50)
                let viewSize = WSVideoSubtitles.getVideoSize(path: path)
                let width = viewSize.width
                let height = text.height(width, font: font, lineBreakMode: NSLineBreakMode.byTruncatingTail)
                let x = CGFloat(30)
                let y = viewSize.height - height/2 - 30
                let layer = CALayer.createTextLayer(text: text, color: UIColor.cyan, font: font, startTime: Double(index) * 2.5 + 2.5, duration: 2.5, textRect: CGRect(x: x, y: y, width: width, height: height), viewSize: viewSize)
                subTitleLayer.addSublayer(layer)
            }
            videoSubTitlesTool.subTitlesLayer = subTitleLayer
            videoSubTitlesTool.addSubTitles(videoPath: path) { [weak self] (finish) in
                guard let `self` = self else{ return }
                self.loadingView.stopAnimating()
                let endTime = Date().timeIntervalSince1970
                print(endTime - startTime)
                if finish {
                    guard let aPath = self.videoSubTitlesTool.outputURL else {return}
                    let request = URLRequest(url: URL(fileURLWithPath: aPath))
                    self.webView.loadRequest(request)
                }
            }
        }
    }
}

