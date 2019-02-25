//
//  API.swift
//  VirtualTourist
//
//  Created by Ahmed Fahmy on 21/02/2019.
//  Copyright © 2019 Mohtaref. All rights reserved.
//

import Foundation
import UIKit


class API{
    
    
    
    struct FlickrParams{
        static let APIKey = "e642c34c6ac8532ef77a7ec1c221babc"
        static let FlickrUrl = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FlickrParams.APIKey)&format=json&nojsoncallback=1&per_page=10"
        
        

        static func getBBox(lat: Double, lon:Double) -> String{
            let minLat = max(lat-1, -90)
            let minLon = max(lon-1, -180)
            let maxLat = min(lat+1, 90)
            let maxLon = min(lon+1, 180)
            return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
        }
    }
    
    static func getPhotoUrl (photoId: String, serverId: String, farmId:Int, secret: String) -> String {
        let url = "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret).jpg"
        return url
    }
    
    
    static func getFlickerImagesUrls(lat: Double,lon: Double,page: Int, compeletion: @escaping ([String])-> Void){
        var UrlsArray: [String] = []
        
        guard let url = URL(string: FlickrParams.FlickrUrl + "&lat=\(lat)&lon=\(lon)&page=\(page)&bbox=\(FlickrParams.getBBox(lat: lat, lon: lon))") else { return }
        let session = URLSession.shared
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult?["stat"] as? String, stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key 'photo' in \(photosDictionary)")
                return
            }
            
            
            if photosArray.count == 0 {
                print("No Photos Found. Search Again.")
                return
            } else {
                for photo in photosArray{
                    guard let photoId = photo["id"] as? String else {
                        print("Cannot find key 'id' in \(photo)")
                        continue
                    }
                    guard let serverId = photo["server"] as? String else {
                        print("Cannot find key 'server' in \(photo)")
                        continue
                    }
                    guard let farmId = photo["farm"] as? Int else {
                        print("Cannot find key 'farm' in \(photo)")
                        continue
                    }
                    guard let secret = photo["secret"] as? String else {
                        print("Cannot find key 'secret' in \(photo)")
                        continue
                    }
                    let farmedUrl = getPhotoUrl(photoId: photoId, serverId: serverId, farmId: farmId, secret: secret)
                   UrlsArray.append(farmedUrl)
                  
                }
                compeletion(UrlsArray)
        }
    }
        
        task.resume()
}
}
