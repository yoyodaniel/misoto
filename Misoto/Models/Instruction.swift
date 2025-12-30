//
//  Instruction.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct Instruction: Codable {
    var text: String
    var imageURL: String?
    var videoURL: String?
    
    init(
        text: String,
        imageURL: String? = nil,
        videoURL: String? = nil
    ) {
        self.text = text
        self.imageURL = imageURL
        self.videoURL = videoURL
    }
}

