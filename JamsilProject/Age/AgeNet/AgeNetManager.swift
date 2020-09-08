//
//  AgeNet.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/08.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreML
import Vision
import UIKit

protocol AgeNetManagerDelegate: AnyObject {
    func ageNet(age: String, confidence: Int)
}

class AgeNetManager {

    private let ageModel: VNCoreMLModel
    weak var delegate: AgeNetManagerDelegate?

    init() throws {
        self.ageModel = try VNCoreMLModel(for: AgeNet().model)
    }
    
    public func requestAge(ciImage: CIImage) {
         // Create request for Vision Core ML model created
         let request = VNCoreMLRequest(model: ageModel) { [weak self] request, error in
             guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                   fatalError("unexpected result type from VNCoreMLRequest")
             }
            
            DispatchQueue.main.async {
                self?.delegate?.ageNet(age: topResult.identifier, confidence: Int(topResult.confidence * 100))
            }
        }

        // Run the Core ML AgeNet classifier on global dispatch queue
        let handler = VNImageRequestHandler(ciImage: ciImage)
              DispatchQueue.global(qos: .userInteractive).async {
              do {
                  try handler.perform([request])
              } catch {
                  print(error)
              }
        }
    }
}
