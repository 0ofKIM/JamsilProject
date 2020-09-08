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
    
    var noiseView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    var leftEyeView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    var rightEyeView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    var leftShoulder: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    var rightShoulder: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    
    @IBOutlet private var previewImageView: UIImageView!

    @IBOutlet weak var videoPreview: UIView!
    var videoCapture: VideoCapture!
    
    private var poseNet: PoseNet?
    private var currentFrame: CGImage?
    
    private var ageNet: AgeNetManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noiseView.backgroundColor = .red
        leftEyeView.backgroundColor = .orange
        rightEyeView.backgroundColor = .yellow
        leftShoulder.backgroundColor = .green
        rightShoulder.backgroundColor = .cyan
        
        self.view.addSubview(noiseView)
        self.view.addSubview(leftEyeView)
        self.view.addSubview(rightEyeView)
        self.view.addSubview(leftShoulder)
        self.view.addSubview(rightShoulder)
        
        do {
            poseNet = try PoseNet()
            ageNet = try AgeNetManager()
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }
        
        self.poseNet?.delegate = self
        self.ageNet?.delegate = self
        
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
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer, image: CGImage?) {
        if let value = image {
            poseNet?.predict(image: value)
            self.currentFrame = image
            
            let ciImage = CIImage(cgImage: value)
            ageNet?.requestAge(ciImage: ciImage)
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

        let dstImageSize = CGSize(width: currentFrame.width, height: currentFrame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()

        let ratio = self.view.frame.size.width / dstImageSize.width

        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)
        
        let dstImage = renderer.image { rendererContext in
            
            for pose in poses {
                
                for joint in pose.joints.values.filter({ $0.isValid }) {

                    let cgContext = rendererContext.cgContext
                    cgContext.setFillColor(UIColor.red.cgColor)
                    
                    let rectangle = CGRect(x: joint.position.x * ratio, y: joint.position.y + (abs(dstImageSize.height - self.view.frame.size.height)) ,
                                           width: 3 * 2, height: 3 * 2)
                    if joint.name == .nose {
                        self.noiseView.frame = rectangle
                    }
                    if joint.name == .leftEye {
                        self.leftEyeView.frame = rectangle
                    }
                    if joint.name == .rightEye {
                        self.rightEyeView.frame = rectangle
                    }
                    if joint.name == .rightShoulder {
                        self.rightShoulder.frame = rectangle
                    }
                    if joint.name == .leftShoulder {
                        self.leftShoulder.frame = rectangle
                    }
                }
            }
        }
        self.previewImageView.image = dstImage
    }
    
}

extension ViewController: AgeNetManagerDelegate {
    func ageNet(age: String, confidence: Int) {
        print("추정나이 : \(age)")
        print("정확도 : \(confidence)")
    }
}
