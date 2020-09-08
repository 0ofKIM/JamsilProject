//
//  PoseBuilder.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/04.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreGraphics

//앱 환경 설정
struct PoseConfiguration {
    
    //포즈안 유효 관절의 최소값(0에 가까울 수록 정확도 올라가진다.)
    var jointConfidenceThreshold = 0.1
    
    //멀티용 알고리즘인지 아닌지
    var isMultiAlgorithm = false
    
}

struct PoseBuilder {
    
    let output: PoseNetOutPut
    let configuration: PoseConfiguration
    let modelToInputTransformation: CGAffineTransform
    
    init(output: PoseNetOutPut, configuration: PoseConfiguration, inputImage: CGImage) {
        self.output = output
        self.configuration = configuration

        modelToInputTransformation = CGAffineTransform(scaleX: CGFloat(inputImage.width) / output.modelInputSize.width,
                                                       y: CGFloat(inputImage.height) / output.modelInputSize.height)
    }
}

//sigle
//일단 싱글만 개발
extension PoseBuilder {

    var pose: Pose {
        var pose = Pose()
        //
        pose.joints.values.forEach { joint in
            configure(joint: joint)
        }

        // 포즈의 상태 할당
        pose.confidence = pose.joints.values
            .map { $0.confidence }.reduce(0, +) / Double(Joint.numberOfJoints)

        // 포즈의 관절 위치 할당
        pose.joints.values.forEach { joint in
            joint.position = joint.position.applying(modelToInputTransformation)
        }

        return pose
    }

    // Joint 클래스의 상태값이 가장 높은 셀을 사용하는 프로피티 추출
    private func configure(joint: Joint) {

        var bestCell = PoseNetOutPut.Cell(0, 0)
        var bestConfidence = 0.0
        for yIndex in 0..<output.height {
            for xIndex in 0..<output.width {
                let currentCell = PoseNetOutPut.Cell(yIndex, xIndex)
                let currentConfidence = output.confidence(for: joint.name, at: currentCell)

                if currentConfidence > bestConfidence {
                    bestConfidence = currentConfidence
                    bestCell = currentCell
                }
            }
        }

        // Update joint.
        joint.cell = bestCell
        joint.position = output.position(for: joint.name, at: joint.cell)
        joint.confidence = bestConfidence
        joint.isValid = joint.confidence >= configuration.jointConfidenceThreshold
    }
}
