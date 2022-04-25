//
//  SettingView.swift
//  Object Capture
//
//  Created by Yuhao Chen on 4/25/22.
//

import SwiftUI
import RealityKit

var tempFileUrl: URL {
    return FileManager.default.temporaryDirectory
}

struct ProcessView: View {
    @Binding var currentView : Views
    var session : PhotogrammetrySession
    var quality : String
    var filename : String
    
    @State private var showingExporter = false
    @State private var showingAlert = false
    @State private var errorMsg : String?
    @State private var constructAmount = 0.0
    @State private var saveFileURL : URL?
    
    var body: some View {
        VStack() {
            Spacer()
            ProgressView("Constructing...", value: constructAmount)
                .padding()
            Spacer()
        }
        .onAppear{
            Task {
                do {
                    if quality == "Preview" {
                        let tempUrl = tempFileUrl.appendingPathComponent("Object Capture \(filename)_\(quality)").appendingPathExtension("usdz")
                        try session.process(requests: [.modelFile(url: tempUrl, detail: .preview)])
                    } else if quality == "Reduced" {
                        let tempUrl = tempFileUrl.appendingPathComponent("Object Capture \(filename)_\(quality)").appendingPathExtension("usdz")
                        try session.process(requests: [.modelFile(url: tempUrl, detail: .reduced)])
                    } else if quality == "Medium" {
                        let tempUrl = tempFileUrl.appendingPathComponent("Object Capture \(filename)_\(quality)").appendingPathExtension("usdz")
                        try session.process(requests: [.modelFile(url: tempUrl, detail: .medium)])
                    } else if quality == "Full" {
                        let tempUrl = tempFileUrl.appendingPathComponent("Object Capture \(filename)_\(quality)").appendingPathExtension("usdz")
                        try session.process(requests: [.modelFile(url: tempUrl, detail: .full)])
                    } else if quality == "Raw" {
                        let tempUrl = tempFileUrl.appendingPathComponent("Object Capture \(filename)_\(quality)").appendingPathExtension("usdz")
                        try session.process(requests: [.modelFile(url: tempUrl, detail: .raw)])
                    }
                } catch {
                    errorMsg = "Construction error! \(error)"
                    print("Construction error! \(error)")
                }
            }
            Task {
                do {
                    print("Session started")
                    for try await output in session.outputs {
                        switch output {
                        case .requestProgress(_, let fraction):
                            constructAmount = fraction
                            print("Request progress: \(fraction)")
                        case .requestComplete(_, let result):
                            if case .modelFile(let url) = result {
                                saveFileURL = url
                                showingExporter = true
                                print("Request result output at \(url).")
                            }
                        case .requestError(let request, let error):
                            print("Error: \(request) error=\(error)")
                        case .processingComplete:
                            print("Completed!")
                        default:  // Or handle other messages...
                            break
                        }
                    }
                } catch {
                    errorMsg = "Fatal session error! \(error)"
                    print("Fatal session error! \(error)")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                Button {
                    //currentTask.cancel()
                    currentView = Views.InputView
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Construction error"),
                message: Text(errorMsg ?? "Session consruction failed with error."),
                dismissButton: .default(Text("Got it!"))
            )
        }
        .navigationTitle("Object Capture")
        .navigationSubtitle("Settings")
        .frame(minWidth: 300, idealWidth: 500 ,maxWidth:.infinity, minHeight: 300, idealHeight: 500, maxHeight: .infinity)
        .fileMover(isPresented: $showingExporter, file: saveFileURL) { result in
            switch result {
                case .success(let url):
                    print("Saved to \(url)")
                    currentView = Views.InputView
                case .failure(let error):
                    errorMsg = "Couldn't Save File \(error)"
                    showingAlert = true
                    print(error.localizedDescription)
                    currentView = Views.InputView
                }
        }
    }
}
