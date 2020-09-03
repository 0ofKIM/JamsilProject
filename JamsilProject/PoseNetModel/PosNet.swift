//
//  PosNet.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/03.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreML
import Vision

class PoseNet {
    let modelInputSize = CGSize(width: 513, height: 513)
    let outputStride = 16
    private let poseNetMLModel: MLModel
    
    init() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
    }
    
    public func predict(image: CGImage) {
        let input = PoseNetInput(image: image, size: self.modelInputSize)
        guard let prediction = try? self.poseNetMLModel.prediction(from: input) else {
            return
        }
        print(input)
    }
}

class PoseNetInput: MLFeatureProvider {
    var featureNames: Set<String> {
        return ["image"]
    }
    var imageFeature: CGImage
    let imageFeatureSize: CGSize
    
    init(image: CGImage, size: CGSize) {
        imageFeature = image
        imageFeatureSize = size
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        guard featureName == "image" else {
            return nil
        }

        let options: [MLFeatureValue.ImageOption: Any] = [
            .cropAndScale: VNImageCropAndScaleOption.scaleFill.rawValue
        ]

        return try? MLFeatureValue(cgImage: imageFeature,
                                   pixelsWide: Int(imageFeatureSize.width),
                                   pixelsHigh: Int(imageFeatureSize.height),
                                   pixelFormatType: imageFeature.pixelFormatInfo.rawValue,
                                   options: options)
    }
}

class PoseNetOutPut {
    
}
