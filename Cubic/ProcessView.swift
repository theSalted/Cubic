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
    var outputPath : URL?
    
    @State private var showingExporter = false
    @State private var showingAlert = false
    @State private var cancelTasks = false
    @State private var errorMsg : String?
    @State private var constructAmount = 0.0
    @State private var saveFileURL : URL?
    @State private var processSession: Task<Void, Error>?
    @State private var monitorSession: Task<Void, Error>?
    
    func goBack() {
        monitorSession?.cancel()
        processSession?.cancel()
        currentView = Views.InputView
    }
    
    var body: some View {
        VStack() {
            Spacer()
            ProgressView(constructAmount == 1.0 ? "Saving Files..." :"Constructing...", value: constructAmount)
                .padding()
            Spacer()
        }
        .onAppear{
            processSession = Task {
                if Task.isCancelled {
                    errorMsg = "Task Canceled"
                    showingAlert = true
                    print("Task Canceled")
                }
                do {
                    if outputPath == nil {
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
                    } else {
                        if quality == "Preview" {
                            try session.process(requests: [.modelFile(url: outputPath!, detail: .preview)])
                        } else if quality == "Reduced" {
                            try session.process(requests: [.modelFile(url: outputPath!, detail: .reduced)])
                        } else if quality == "Medium" {
                            try session.process(requests: [.modelFile(url: outputPath!, detail: .medium)])
                        } else if quality == "Full" {
                            try session.process(requests: [.modelFile(url: outputPath!, detail: .full)])
                        } else if quality == "Raw" {
                            try session.process(requests: [.modelFile(url: outputPath!, detail: .raw)])
                        }
                    }
                } catch {
                    errorMsg = "Construction error: \(error)"
                    showingAlert = true
                    print("Construction error! \(error)")
                }
            }
            monitorSession = Task {
                if Task.isCancelled {
                    print("Task Canceled")
                }
                do {
                    print("Session started")
                    for try await output in session.outputs {
                        switch output {
                        case .requestProgress(_, let fraction):
                            constructAmount = fraction
                            print("Request progress: \(fraction)")
                        case .requestComplete(_, let result):
                            if case .modelFile(let url) = result {
                                if(outputPath == nil) {
                                    saveFileURL = url
                                    showingExporter = true
                                } else {
                                    currentView = Views.InputView
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: outputPath!.path)
                                }
                                print("Request result output at \(url).")
                            }
                        case .requestError(let request, let error):
                            print("Error: \(request) error=\(error)")
                            errorMsg = "Fatal session error: \(error)"
                            showingAlert = true
                        case .processingComplete:
                            print("Completed!")
                        default:  // Or handle other messages...
                            break
                        }
                    }
                } catch {
                    errorMsg = "Fatal session error: \(error)"
                    showingAlert = true
                    print("Fatal session error! \(error)")
                    processSession?.cancel()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                Button {
                    //currentTask.cancel()
                    goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Construction error"),
                message: Text(errorMsg ?? "Session consruction failed with error."),
                dismissButton: Alert.Button.default(
                        Text("Got it!"), action: {
                            goBack()
                        }
                    )
            )
        }
        .navigationTitle("Cubic")
        .navigationSubtitle("Processing")
        .frame(minWidth: 300, idealWidth: 500 ,maxWidth:.infinity, minHeight: 300, idealHeight: 500, maxHeight: .infinity)
        .fileMover(isPresented: $showingExporter, file: saveFileURL) { result in
            switch result {
                case .success(let url):
                    print("Saved to \(url)")
                    goBack()
                case .failure(let error):
                    errorMsg = "Couldn't Save File \(error)"
                    showingAlert = true
                    print(error.localizedDescription)
                    goBack()
                }
        }
    }
}
