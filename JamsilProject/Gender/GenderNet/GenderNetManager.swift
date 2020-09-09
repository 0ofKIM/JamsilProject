//
//  GenderNetManager.swift
//  JamsilProject
//
//  Created by mmxsound on 2020/09/09.
//  Copyright © 2020 jamsil. All rights reserved.
//

import CoreML
import Vision
import UIKit

protocol GenderNetManagerDelegate: AnyObject {
    func genderNet(gender: String)
}

class GenderNetManager {

    private let ageModel: VNCoreMLModel
    weak var delegate: GenderNetManagerDelegate?

    init() throws {
        self.ageModel = try VNCoreMLModel(for: GenderClass_1().model)
    }
    
    public func requestAge(ciImage: CIImage) {
         // Create request for Vision Core ML model created
         let request = VNCoreMLRequest(model: ageModel) { [weak self] request, error in
             guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
                   fatalError("unexpected result type from VNCoreMLRequest")
             }
            
            DispatchQueue.main.async {
                self?.delegate?.genderNet(gender: topResult.identifier)
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

