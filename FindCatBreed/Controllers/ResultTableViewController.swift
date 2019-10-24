//
//  ResultTableViewController.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 18/09/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import SafariServices


// MARK: - Breed Cell
class BreedCell: UITableViewCell {
    var data : (breed: BreedDatabase.Breed, confidence: Float)? {
        didSet {
            breedTextLabel.text = data!.breed.name + " (" +  String(format: "%.2f", data!.confidence) + ")"
            confidenceBar.confidenceRatio = data!.confidence
        }
    }
    
    @IBOutlet var breedTextLabel: UILabel!
    @IBOutlet var confidenceBar: ConfidenceBar!
}


// MARK: - Preview Cell

class PreviewCell: UITableViewCell{
    
    
    @IBOutlet var previewImageView: UIImageView!
    
    override var backgroundColor: UIColor? {
        get {
            return .black
        }
        
        set {}
    }
    
    var previewImage : UIImage? {
        didSet {
            previewImageView?.image = previewImage
        }
    }
}

// MARK: - ConfidenceBar
class ConfidenceBar : UIView {
    
    var didAnimate: Bool = false
    
    let baseWidthRatio: Float = 0.15
    
    var confidenceRatio: Float = 0 {
        didSet {
            updateWidth()
        }
    }
    
    var width : Float {
        return Float(self.frame.width) * min(baseWidthRatio * confidenceRatio, 1)
    }
    
    var color : UIColor {
        
        if confidenceRatio >= 3 {
            return .systemGreen
        } else if confidenceRatio >= 2 {
            return .systemOrange
        } else {
            return .systemGray3
        }
        
    }
    
    let bar: UIView = UIView()
    
    func setup() {
        debugPrint("setup")
        self.backgroundColor = .clear
        bar.layer.masksToBounds = true
        bar.layer.cornerRadius = 5
        bar.layer.opacity = 1
        bar.frame = CGRect(origin: .zero, size: CGSize(width: .zero, height: frame.size.height))
        
        addSubview(bar)
    }
    
    override convenience init(frame: CGRect) {
        self.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func updateWidth() {
        
        self.bar.backgroundColor = color
        self.bar.frame = CGRect(x: self.bar.frame.minX, y: self.bar.frame.minY, width: CGFloat(self.width), height: self.bar.frame.height)
        
    }
    
    func animate() {
        
        bar.frame = CGRect(origin: .zero, size: CGSize(width: .zero, height: frame.size.height))
        
        UIView.animate(
        withDuration: 0.6,
        delay: 0.2,
        animations: {
            self.bar.frame = CGRect(x: self.bar.frame.minX, y: self.bar.frame.minY, width: CGFloat(self.width), height: self.bar.frame.height)
            
            self.bar.layer.opacity = 1
        },
        completion: nil)
    }
}


// MARK: - ResultTableViewController

class ResultTableViewController: UITableViewController{
    
    var results : CatAnalyzer.ClassificationResult = []
    var previewImage : UIImage?;
    
    override func viewWillAppear(_ animated: Bool) {
        
        tableView.visibleCells.forEach { (cell: UITableViewCell) in
            if let breedCell = cell as? BreedCell {
                breedCell.confidenceBar.animate()
            }
        }
    }
    
    public func populate(results: CatAnalyzer.ClassificationResult, image: UIImage){
        self.results = results
        self.previewImage = image
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return results.count
        } else {
            fatalError("Unexpected tableview section : \(section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(indexPath.section == 1) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath) as! BreedCell
            let resultEntry = results[indexPath.row]
            
            cell.data = (breed: BreedDatabase.getBreed(identifier: resultEntry.0), confidence: resultEntry.1)
            
            return cell
                
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewCell", for: indexPath) as! PreviewCell
            cell.previewImage = previewImage
            
            return cell
        }
    }
    
    func handleNetworkError() {
        
        let alert = UIAlertController(title: NSLocalizedString("Network error", comment: "Network error dialog title"), message: NSLocalizedString("Check your internet connection to access Wikipedia.", comment: "Network error dialog description"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            return
        }
        
        let breedCell = tableView.cellForRow(at: indexPath) as! BreedCell
        
        WikipediaLocalizer.shared.localizeFromEnglish(title: breedCell.data!.breed.wikipediaSlug!, errorHandler: handleNetworkError) { url in
            
            let webView = SFSafariViewController(url: url)
            
            DispatchQueue.main.async {
                self.showDetailViewController(webView, sender: nil)
            }
        }
    }
    
}
