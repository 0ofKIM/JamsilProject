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
    
    @IBOutlet weak var customView: UIView!
    @IBOutlet weak var videoPreview: UIView!
    var videoCapture: VideoCapture!
    
    private var poseNet: PoseNet?
    private var currentFrame: CGImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            poseNet = try PoseNet()
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }
        
        self.poseNet?.delegate = self
        
        self.setUpCamera()
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
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer, timestamp: CMTime, image: CGImage?) {
        if let value = image {
            poseNet?.predict(image: value)
            self.currentFrame = image
        }
    }
}

extension ViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict prediction: PoseNetOutPut) {
        guard let currentFrame = self.currentFrame else {
            return
        }
        let poseBuilderConfiguration = PoseConfiguration()
        let poseBuilder = PoseBuilder(output: prediction, configuration: poseBuilderConfiguration, inputImage: currentFrame)
        
        let poses = [poseBuilder.pose]
        
        for (index, pose) in poses.enumerated() where pose.confidence > 0.9 {
            for joint in pose.joints {
                
                //print(joint.value.confidence)
                //print("\(index) : \(joint.value.name) : \(joint.value.position)")
                if joint.value.name == .nose {
                    DispatchQueue.main.async {
                        print("\(index) : \(joint.value.name) : \(joint.value.position)")
                        self.customView.frame = CGRect(x: joint.value.position.x, y: joint.value.position.y, width: 10, height: 10)
                    }
                }

            }
        }
        
//        
//        if poses[0].confidence > 0.8 {
//            print("x : \(poses[0].joints[.leftAnkle]?.position.x)")
//            print("y : \(poses[0].joints[.leftAnkle]?.position.y)")
//        }
    }
    
}
