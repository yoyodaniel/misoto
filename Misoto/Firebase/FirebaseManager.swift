//
//  FirebaseManager.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    
    private init() {
        // Firebase will be configured in MisotoApp.swift
    }
    
    var firestore: Firestore {
        return db
    }
}

