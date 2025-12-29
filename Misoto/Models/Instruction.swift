//
//  Instruction.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct Instruction: Identifiable, Codable {
    var id: String
    var text: String
    var imageURL: String?
    var videoURL: String?
    
    init(
        id: String = UUID().uuidString,
        text: String,
        imageURL: String? = nil,
        videoURL: String? = nil
    ) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.videoURL = videoURL
    }
}

