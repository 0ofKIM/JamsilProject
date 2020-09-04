//
//  PosNet.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/03.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreML
import Vision

protocol PoseNetDelegate: AnyObject {
    func poseNet(_ poseNet: PoseNet, didPredict prediction: PoseNetOutPut)
}

class PoseNet {
    
    weak var delegate: PoseNetDelegate?
    
    //Model's 스팩
    //PoseNetMobileNet 모델 의 인풋 사이즈(모델 스팩)
    let modelInputSize = CGSize(width: 513, height: 513)
    //PoseNetMobileNet 모델의 output stride - 모델의 그리드간 간격, 간격이 적을 수록 고해상도(모델 스팩)
    let outputStride = 16
    //모델
    private let poseNetMLModel: MLModel
    
    init() throws {
        poseNetMLModel = try PoseNetMobileNet075S16FP16(configuration: .init()).model
    }
    
    public func predict(image: CGImage) {
        let input = PoseNetInput(image: image, size: self.modelInputSize)
        guard let prediction = try? self.poseNetMLModel.prediction(from: input) else {
            return
        }
        
        let poseNetOutput = PoseNetOutPut(prediction: prediction, modelInputSize: self.modelInputSize, modelOuputSize: self.outputStride)
        
        DispatchQueue.main.async {
            self.delegate?.poseNet(self, didPredict: poseNetOutput)
        }
    }
}

class PoseNetInput: MLFeatureProvider {
    
    //PoseNetMobileNet075S16FP16Input 의 input feature의 네임(해당 클래스에 image 라 지정 되어있음)
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

struct PoseNetOutPut {
    
    //하기 프로퍼티들은 PoseNet에서 제공
    //PoseNet에서 제공하는 각각의 관절의 신뢰도를 저장하는 다차원 배열(1차원 아님)
    let heatMap: MLMultiArray
    //PoseNet에서 제공하는 각각의 관절의 offset 저장하는 다차원 배열(1차원 아님)
    let offsets: MLMultiArray
    //PoseNet에서 제공하는 각각의 관절에서 그 관절의 부모까지 저장하는 다차원 배열(1차원 아님)
    let backwardDisplacementMap: MLMultiArray
    //PoseNet에서 제공하는 각각의 부모관절에서 자식중 하나로 변위 벡터를 저장하는 다차원 배열(1차원 아님)
    let forwardDisplacementMap: MLMultiArray
    //모델 인풋 사이즈
    let modelInputSize: CGSize
    //모델 아웃풋 그리드
    //출력 객체의 보폭이라고 생각하면된다.
    let modelOutputStride: Int
    //
    //객체 높이
    var height: Int {
        return heatMap.shape[1].intValue
    }
    //객체 너비
    var width: Int {
        return heatMap.shape[2].intValue
    }
    
    struct Cell {
        let yIndex: Int
        let xIndex: Int

        init(_ yIndex: Int, _ xIndex: Int) {
            self.yIndex = yIndex
            self.xIndex = xIndex
        }

        static var zero: Cell {
            return Cell(0, 0)
        }
    }
    
    init(prediction: MLFeatureProvider, modelInputSize: CGSize, modelOuputSize: Int) {
        guard let heatMap = prediction.featureValue(for: "heatmap")?.multiArrayValue else {
            fatalError("heatMap error")
        }
        guard let offsets = prediction.featureValue(for: "offsets")?.multiArrayValue  else {
            fatalError("offsets error")
        }
        guard let backwardDisplacementMap = prediction.featureValue(for: "displacementBwd")?.multiArrayValue  else {
            fatalError("backwardDisplacementMap error")
        }
        guard let forwardDisplacementMap = prediction.featureValue(for: "displacementFwd")?.multiArrayValue  else {
            fatalError("forwardDisplacementMap error")
        }
        self.heatMap = heatMap
        self.offsets = offsets
        self.backwardDisplacementMap = backwardDisplacementMap
        self.forwardDisplacementMap = forwardDisplacementMap
        self.modelInputSize = modelInputSize
        self.modelOutputStride = modelOuputSize
    }
    
    //특정 그리 셀에 주어진 관절 타입의 신뢰도 계산
    func confidence(for jointName: Joint.Name, at cell: Cell) -> Double {
        
        let multiArrayIndex = [jointName.rawValue, cell.yIndex, cell.xIndex]
        var numbers: [NSNumber] = []
        
        for index in multiArrayIndex {
            let num = NSNumber.init(value: index)
            numbers.append(num)
        }
        
        return heatMap[numbers].doubleValue
    }
    
    //특정 그리 셀에 주어진 관절 타입의 위치 계산
    func position(for jointName: Joint.Name, at cell: Cell) -> CGPoint {
        let jointOffset = offset(for: jointName, at: cell)

        let jointPosition = CGPoint(x: cell.xIndex * modelOutputStride,
                                    y: cell.yIndex * modelOutputStride)
        
        let offset = CGPoint(x: jointOffset.dx, y: jointOffset.dy)
        
        let resutPosition = CGPoint(x: jointPosition.x + offset.x, y: jointPosition.y + offset.y)

        return resutPosition
    }
    
    //특정 그리 셀에 주어진 관절 타입의 오프셋 계산
    //오프셋에서 얻은 값을 통해 위치 계산 한다.
    func offset(for jointName: Joint.Name, at cell: Cell) -> CGVector {

        let yOffsetIndex = [jointName.rawValue, cell.yIndex, cell.xIndex]
        let xOffsetIndex = [jointName.rawValue + Joint.numberOfJoints, cell.yIndex, cell.xIndex]
        
        var yNumbers: [NSNumber] = []
        var xNumbers: [NSNumber] = []
         
        for index in yOffsetIndex {
            let num = NSNumber.init(value: index)
            yNumbers.append(num)
        }
        
        for index in xOffsetIndex {
            let num = NSNumber.init(value: index)
            xNumbers.append(num)
        }

        // Obtain y and x component of the offset from the offsets array.
        let offsetY: Double = offsets[yNumbers].doubleValue
        let offsetX: Double = offsets[xNumbers].doubleValue

        return CGVector(dx: CGFloat(offsetX), dy: CGFloat(offsetY))
    }
}
