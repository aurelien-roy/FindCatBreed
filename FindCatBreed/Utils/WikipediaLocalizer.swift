//
//  WikipediaLocalizer.swift
//  FindCatBreed
//
//  Created by Aurélien Roy on 24/10/2019.
//  Copyright © 2019 Aurélien Roy. All rights reserved.
//

import Foundation

class WikipediaLocalizer {
    
    let preferredLanguages = NSLocale.preferredLanguages
    
    static let shared = WikipediaLocalizer()
    
    func localizeFromEnglish(title: String, errorHandler: @escaping () -> Void, completionHandler: @escaping (URL) -> Void) {
        
        // Return article as is if English is the prefered language
        if preferredLanguages.first!.starts(with: "en") {
            completionHandler(
                wikipediaURL(locale: "en", title: title)
            )
        }
        
        // Get all available languages from Wikipedia
        fetchArticleAlternateLanguages(originalLang: "en", title: title, errorHandler: errorHandler) { alternateLangDict in
            
            for lang in self.preferredLanguages {
                
                let lang = String(lang.split(separator: "-").first!)
                
                if let title = alternateLangDict[lang] {
                    completionHandler(
                        self.wikipediaURL(locale: lang, title: title)
                    )
                    return
                }
            }
            
            // Fallback to English
            completionHandler(
                self.wikipediaURL(locale: "en", title: title)
            )
        }
    }
    
    func wikipediaDomainPrefix(_ locale: String) -> String {
        return "https://" + locale + ".wikipedia.org"
    }
    
    func wikipediaURL(locale: String, title: String) -> URL {
        return URL(string: wikipediaDomainPrefix(locale) + "/wiki/" + title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    }
    
    func wikipediaLangApiURL(locale: String, title: String) -> URL {
        return URL(string: wikipediaDomainPrefix(locale) + "/w/api.php?action=query&prop=langlinks&format=json&lllimit=500&titles=" + title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    }
    
    func fetchArticleAlternateLanguages(originalLang: String, title: String, errorHandler: @escaping () -> Void, completionHandler: @escaping ([String: String]) -> Void) {
        
        let url = wikipediaLangApiURL(locale: originalLang, title: title)
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                error == nil,
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                response?.mimeType == "application/json"
            else {
                errorHandler()
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                
                let query = json["query"] as! [String: Any]
                let pages = query["pages"] as! [String: Any]
                
                let page = pages.first!.value as! [String: Any]
                let langlinks = page["langlinks"] as! [[String: Any]]
                
                let langDict = Dictionary(uniqueKeysWithValues: langlinks.map { ($0["lang"] as! String, $0["*"] as! String) })
                
                completionHandler(langDict)
                
                
            } catch {
                errorHandler()
            }
            
        }.resume()
    }
    
}
