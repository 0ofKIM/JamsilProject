//
//  Joint.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/04.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreGraphics

class Joint {
    enum Name: Int, CaseIterable {
        case nose
        case leftEye
        case rightEye
        case leftEar
        case rightEar
        case leftShoulder
        case rightShoulder
        case leftElbow
        case rightElbow
        case leftWrist
        case rightWrist
        case leftHip
        case rightHip
        case leftKnee
        case rightKnee
        case leftAnkle
        case rightAnkle
    }

    //총 관절 개수
    static var numberOfJoints: Int {
        return Name.allCases.count
    }

    //관절 Identity
    let name: Name

    //관절 개별 위치
    var position: CGPoint

    //관절을 각각 (그리드라 두고) 셀(x,y)
    var cell: PoseNetOutPut.Cell
    
    //애플에서 제공하는 모델에서 추력하는 heatMap 배열 - 관절의 상태
    var confidence: Double

    //관절 인식 상태
    var isValid: Bool

    init(name: Name,
         cell: PoseNetOutPut.Cell = .zero,
         position: CGPoint = .zero,
         confidence: Double = 0,
         isValid: Bool = false) {
        self.name = name
        self.cell = cell
        self.position = position
        self.confidence = confidence
        self.isValid = isValid
    }
}

