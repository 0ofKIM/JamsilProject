//
//  ViewController.swift
//  JamsilProject
//
//  Created by Lotte on 2020/08/22.
//  Copyright © 2020 jamsil. All rights reserved.
//

import AVFoundation
import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var videoPreview: UIView!
    var videoCapture: VideoCapture!
    
    private var poseNetMLModel: MLModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try self.setUpModel()
        } catch {
            print(error)
        }
       
        self.setUpCamera()
    }

    func setUpModel() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    DispatchQueue.main.async {
                        self.videoPreview.layer.addSublayer(previewLayer)
                        self.videoCapture.previewLayer?.frame = self.videoPreview.bounds
                    }
                }

                self.videoCapture.start()
            }
        }
    }
}

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer, timestamp: CMTime) {
        
    }
}
