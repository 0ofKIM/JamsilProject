//
//  Pose.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/04.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreGraphics

struct Pose {
    //2 관절 사이
    struct Edge {
        let index: Int
        let parent: Joint.Name
        let child: Joint.Name

        init(from parent: Joint.Name, to child: Joint.Name, index: Int) {
            self.index = index
            self.parent = parent
            self.child = child
        }
    }
    
    //각각의 관절을 연결 시킴(링크드 리스트 형태로)
    static let edges = [
        Edge(from: .nose, to: .leftEye, index: 0),
        Edge(from: .leftEye, to: .leftEar, index: 1),
        Edge(from: .nose, to: .rightEye, index: 2),
        Edge(from: .rightEye, to: .rightEar, index: 3),
        Edge(from: .nose, to: .leftShoulder, index: 4),
        Edge(from: .leftShoulder, to: .leftElbow, index: 5),
        Edge(from: .leftElbow, to: .leftWrist, index: 6),
        Edge(from: .leftShoulder, to: .leftHip, index: 7),
        Edge(from: .leftHip, to: .leftKnee, index: 8),
        Edge(from: .leftKnee, to: .leftAnkle, index: 9),
        Edge(from: .nose, to: .rightShoulder, index: 10),
        Edge(from: .rightShoulder, to: .rightElbow, index: 11),
        Edge(from: .rightElbow, to: .rightWrist, index: 12),
        Edge(from: .rightShoulder, to: .rightHip, index: 13),
        Edge(from: .rightHip, to: .rightKnee, index: 14),
        Edge(from: .rightKnee, to: .rightAnkle, index: 15)
    ]
    
    private(set) var joints: [Joint.Name: Joint] = [
        .nose: Joint(name: .nose),
        .leftEye: Joint(name: .leftEye),
        .leftEar: Joint(name: .leftEar),
        .leftShoulder: Joint(name: .leftShoulder),
        .leftElbow: Joint(name: .leftElbow),
        .leftWrist: Joint(name: .leftWrist),
        .leftHip: Joint(name: .leftHip),
        .leftKnee: Joint(name: .leftKnee),
        .leftAnkle: Joint(name: .leftAnkle),
        .rightEye: Joint(name: .rightEye),
        .rightEar: Joint(name: .rightEar),
        .rightShoulder: Joint(name: .rightShoulder),
        .rightElbow: Joint(name: .rightElbow),
        .rightWrist: Joint(name: .rightWrist),
        .rightHip: Joint(name: .rightHip),
        .rightKnee: Joint(name: .rightKnee),
        .rightAnkle: Joint(name: .rightAnkle)
    ]
    //관절 상태
    var confidence: Double = 0.0
    
    //관절 명과 연결된 모든 링크드 리스트 뽑아오기
    static func edges(for jointName: Joint.Name) -> [Edge] {
        return Pose.edges.filter {
            $0.parent == jointName || $0.child == jointName
        }
    }
    
    //연결된 링크드 리스트와 관련된 링크드 리스트 뽑아오기
    static func edge(from parentJointName: Joint.Name, to childJointName: Joint.Name) -> Edge? {
        return Pose.edges.first(where: { $0.parent == parentJointName && $0.child == childJointName })
    }
    
    subscript(jointName: Joint.Name) -> Joint {
        get {
            assert(joints[jointName] != nil)
            return joints[jointName]!
        }
        set {
            joints[jointName] = newValue
        }
    }
}
