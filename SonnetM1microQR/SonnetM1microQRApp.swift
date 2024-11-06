//
//  SonnetM1microQRApp.swift
//  SonnetM1microQR
//
//  Created by Bastiaan Quast on 11/6/24.
//

import SwiftUI

@main
struct SonnetM1microQRApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
