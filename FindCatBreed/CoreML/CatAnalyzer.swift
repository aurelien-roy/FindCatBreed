//
//  CatAnalyzer.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 25/09/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import UIKit
import Vision

class CatAnalyzer{
    
    typealias DetectionCallback = (_ boxs: [CGRect]) -> Void
    typealias ClassificationResult = [(String, Float)]
    typealias ClassificationCallback = (_ scores: ClassificationResult) -> Void
    
    let CAT_IDENTIFIER = "Cat"
    
    let model: VNCoreMLModel
    
    let detectionQueue = DispatchQueue(label: "roy-aurelien.catdetector.detectionTasksQueue", qos: .userInteractive)
    let classificationQueue = DispatchQueue(label: "roy-aurelien.catdetector.classificationTasksQueue")

    struct ClassificationTask{
        var image: CIImage
        var classificationCallback: ClassificationCallback
    }
    
    struct DetectionTask{
        var image: CIImage
        var detectionCallback: DetectionCallback
    }
    
    //MARK: Functions
    
    init() throws{
        model = try VNCoreMLModel(for: CatBreedClassifier().model)
    }
    
    public func createDetectionTask(from image: CIImage, detectionCallback: @escaping DetectionCallback/*, classificationCallback: @escaping ClassificationCallback*/){
        detectionQueue.async {
            //debugPrint("task run")
            self.runTask(
                DetectionTask(image: image, detectionCallback: detectionCallback)
            )
        }
    }
    
    public func createClassificationTask(from image: CIImage, classificationCallback: @escaping ClassificationCallback){
        
        classificationQueue.async {
            self.runTask(
                ClassificationTask(image: image, classificationCallback: classificationCallback)
            )
        }
    }
    
    private func runTask(_ task: ClassificationTask){
        
        let request = VNCoreMLRequest(model: model){ request, error in
            guard let observations = request.results as? [VNClassificationObservation] else {
                debugPrint(error!)
                return
            }
            
            task.classificationCallback(observations.map({ ($0.identifier, $0.confidence) }))
        }
        
        request.imageCropAndScaleOption = .scaleFit
        
        performVisionRequest(request, with: task.image)
    }
    
    private func runTask(_ task: DetectionTask) {
        
        let request = VNRecognizeAnimalsRequest() { request, error in
            guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                debugPrint(error!)
                return
            }
                
            // Keep only cats
            let cats = observations.filter { (o: VNRecognizedObjectObservation) -> Bool in
                return o.labels.first?.identifier == self.CAT_IDENTIFIER
            }
                
            task.detectionCallback(cats.map({ $0.boundingBox }))
        }
        
        performVisionRequest(request, with: task.image)
    }
    
    private func performVisionRequest(_ request: VNImageBasedRequest, with image: CIImage) {
        do{
            try VNImageRequestHandler(ciImage: image).perform([request])
        } catch {
            debugPrint("Unable to perform vision request.")
        }
    }
    
    public func mergeResults(_ results: [ClassificationResult]) -> ClassificationResult {
        
        let resultSortedByKey = results.map({ $0.sorted(by: { $0.0 < $1.0}) })
        
        let classes = resultSortedByKey.first!.map({ $0.0 })
        var confidence = Array(repeating: Float(0), count: classes.count)

        for class_i in 0..<classes.count {
            confidence[class_i] = resultSortedByKey.map({ $0[class_i].1 }).reduce(Float(0), +) / Float(results.count)
        }
        
        return Array(zip(classes, confidence)).sorted(by: { $0.1 > $1.1 })
        
    }
}
