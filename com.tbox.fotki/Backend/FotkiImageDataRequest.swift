//
//  FotkiImageDataRequest.swift
//  com.tbox.fotki
//
//  Created by Apple on 2/14/17.
//  Copyright © 2017 TBoxSolutionz. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

class FotkiImageDataRequest: NSObject {
    //MARK: download cell images
    func imageDownloader(url: String, index: Int, completionHandler: @escaping(DataResponse<Image>, Int) -> Void) {
        Alamofire.request(url).responseImage { response in
            if response.result.value != nil {
                completionHandler(response, index)
            }
        }
    }
}
