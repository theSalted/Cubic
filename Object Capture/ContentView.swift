//
//  ContentView.swift
//  Object Capture
//
//  Created by Yuhao Chen on 4/18/22.
//

import SwiftUI
import RealityKit

enum Views {
  case InputView, Process
}

struct ContentView: View {
    
    @State var path : URL?
    @State var outputPath : URL?
    @State var currentView = Views.InputView
    @State var session : PhotogrammetrySession?
    @State var quality = "Full"
    @State var filename = "Model"
    @State var format = ".usdz"
    
    var body: some View {
        if currentView == Views.InputView {
            InputView(currentView: $currentView, path: $path, outputPath: $outputPath, session: $session, selectedQuality: $quality, filename: $filename, format: $format)
        } else if currentView == Views.Process {
            ProcessView(currentView: $currentView, session: session!, quality: quality, filename: filename, outputPath: outputPath)
        } else {
            InputView(currentView: $currentView, path: $path, outputPath: $outputPath, session: $session, selectedQuality: $quality, filename: $filename, format: $format)
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
