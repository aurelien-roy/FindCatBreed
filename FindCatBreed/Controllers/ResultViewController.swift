//
//  ResultViewController.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 2019-03-24.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import UIKit
import VideoToolbox
import Vision

class ResultViewController : UIViewController{
    
    var image : UIImage!
    
    var results : CatAnalyzer.ClassificationResult = []
    
    private var resultTableController: ResultTableViewController!
    
    
    static func storyboardInstance() -> ResultViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "resultsController") as? ResultViewController
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        resultTableController.populate(results: filterResults(results), image: image)
    }
    
    func filterResults(_ results: CatAnalyzer.ClassificationResult) -> CatAnalyzer.ClassificationResult {
        let nbBreeds = Float(results.count)
        
        return results.map { (a: (String, Float)) -> (String, Float) in
            return (a.0, a.1 * nbBreeds)
        }.filter({ $0.1 >= 1 })
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "ResultTableSegue"){
            self.resultTableController = segue.destination as? ResultTableViewController
        }
    }
    
}
