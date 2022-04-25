//
//  InputView.swift
//  Object Capture
//
//  Created by Yuhao Chen on 4/25/22.
//

import SwiftUI
import RealityKit

func getPhotogrammetrySession(url: URL) async throws -> PhotogrammetrySession {
    return try PhotogrammetrySession(input: url, configuration: PhotogrammetrySession.Configuration())
}

func createConfig(sensitivity: String, ordering: String, enableMasking: Bool) -> PhotogrammetrySession.Configuration {
    
    var config = PhotogrammetrySession.Configuration()
    
    if(sensitivity == "Normal") {
        config.featureSensitivity = .normal
    } else if (sensitivity == "High") {
        config.featureSensitivity = .high
    }
    
    if(ordering == "Unordered") {
        config.sampleOrdering = .unordered
    } else if (ordering == "Sequential") {
        config.sampleOrdering = .sequential
    }
    
    if(enableMasking) {
        config.isObjectMaskingEnabled = true
    } else {
        config.isObjectMaskingEnabled = false
    }
    
    return config
}

struct InputView: View {
    
    var qualities = ["Preview", "Reduced", "Medium", "Full", "Raw"]
    
    @Binding var currentView : Views
    @Binding var path : URL?
    @Binding var session : PhotogrammetrySession?
    @Binding var selectedQuality : String
    @Binding var filename : String
    
    @State private var errorMsg : String?
    @State private var hardwareCheck : Bool?
    
    @State private var showFileChooser = false
    @State private var showingAlert = false
    @State private var showingPopover = false
    
    @State private var sensitivity = "Normal"
    @State private var ordering = "Unordered"
    @State private var enableMasking = true
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            HStack {
                Spacer()
                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    
                    if panel.runModal() == .OK {
                        self.path = panel.url
                        self.filename = panel.url?.lastPathComponent ?? "<none>"
                        
                        print(self.filename)
                        print(self.path ?? "N/A")
                    }
                    
                    Task {
                        do {
                            let config = createConfig(sensitivity: sensitivity, ordering: ordering, enableMasking: enableMasking)
                            
                            session = try PhotogrammetrySession(input: (path ?? URL(string: "//")!), configuration: config)
                            
                            // Switch View to process
                            currentView = Views.Process
                        } catch {
                            print("User creation failed with error: \(error)")
                            errorMsg = "Session creation failed with error: \(error)"
                            showingAlert = true
                        }
                    }
                    
                } label: {
                    VStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 100, weight: .light))
                            .font(Font.title.weight(.medium))
                        .padding()
                        Text("Drag in folder with images to start")
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding([.leading, .bottom, .trailing])
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                Spacer()
            }
            Spacer()
            HStack() {
                if hardwareCheck == nil {
                    HStack {
                        ProgressView()
                            .scaleEffect(1/2)
                        Text("Checking hardware support..")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if hardwareCheck == false {
                    Label {
                        Text("Unsupported compatible")
                    } icon: {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                            .foregroundColor(.red)
                    }
                    .padding()
                } else {
                    Label {
                        Text("Hardware compatible")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) } ) {
                let _ = provider.loadObject(ofClass: URL.self) { object, error in
                    if let url = object {
                        path = url
                        
                        self.filename = path?.lastPathComponent ?? "<none>"
                        
                        print(self.filename)
                        print(self.path ?? "N/A")
                        
                        Task {
                            do {
                                let config = createConfig(sensitivity: sensitivity, ordering: ordering, enableMasking: enableMasking)
                                
                                session = try PhotogrammetrySession(input: (path ?? URL(string: "//")!), configuration: config)
                                
                                // Switch View to process
                                currentView = Views.Process
                            } catch {
                                print("User creation failed with error: \(error)")
                                errorMsg = "Session creation failed with error: \(error)"
                                showingAlert = true
                            }
                        }
                        print("url: \(url)")
                    }
                }
                return true
            }
            return false
        }
        .toolbar {
            ToolbarItemGroup {
                Picker("Quality", selection: $selectedQuality) {
                    ForEach(qualities, id: \.self) {
                        Text($0)
                    }
                }
                
                Button {
                    showingPopover = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .popover(isPresented: $showingPopover) {
                    SettingsView(sensitivity: $sensitivity, ordering: $ordering, enableMasking: $enableMasking)
                }
                Spacer()
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.allowsMultipleSelection = false
                    
                    if panel.runModal() == .OK {
                        self.path = panel.url
                        self.filename = panel.url?.lastPathComponent ?? "<none>"
                        
                        print(self.filename)
                        print(self.path ?? "N/A")
                        Task {
                            do {
                                let config = createConfig(sensitivity: sensitivity, ordering: ordering, enableMasking: enableMasking)
                                
                                session = try PhotogrammetrySession(input: (path ?? URL(string: "//")!), configuration: config)
                                
                                // Switch View to process
                                currentView = Views.Process
                            } catch {
                                print("User creation failed with error: \(error)")
                                errorMsg = "Session creation failed with error: \(error)"
                                showingAlert = true
                            }
                        }
                        
                        print(self.filename)
                        print(self.path ?? "N/A")
                    }
                } label: {
                    Label("Add Photos", systemImage: "plus")
                }
            }
        }
        .onAppear{
            hardwareCheck = supportsObjectCapture()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("No images found"),
                message: Text(errorMsg ?? "Session creation failed with error."),
                dismissButton: .default(Text("Got it!"))
            )
        }
        .navigationTitle("Object Capture")
        .frame(minWidth: 300, idealWidth: 500 ,maxWidth:.infinity, minHeight: 300, idealHeight: 500, maxHeight: .infinity)
    }
}
