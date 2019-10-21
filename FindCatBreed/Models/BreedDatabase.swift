//
//  CatDatabase.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 18/09/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation
import CSV

class BreedDatabase{
    struct Breed : Decodable{
        let identifier: String
        let name: String
        let wikipediaSlug: String?
    }
    
    static let shared = BreedDatabase()
    static let filepath = "cat_database"
    
    var breeds: [String: Breed] = [:]
    
    init(){
        loadFromCSV()
    }
    
    private func loadFromCSV(){
        let path = Bundle.main.path(forResource: BreedDatabase.filepath, ofType: "csv")!
        
        do{
            let csv = try String(contentsOfFile: path)
            let reader = try CSVReader(string: csv, hasHeaderRow: true, delimiter: ";")
            let decoder = CSVRowDecoder()
            
            while(reader.next() != nil){
                let breed = try decoder.decode(Breed.self, from: reader)
                self.breeds[breed.identifier] = breed
                debugPrint("Imported \(breed.name).")
            }
            
        }catch{
            fatalError("Error while importing data : \(error).")
        }
    }
    
    public static func getBreed(identifier: String) -> Breed{
        guard let breed = shared.breeds[identifier] else{
            fatalError("Unkwown breed : \(identifier)")
        }
        
        return breed
    }
    
}
