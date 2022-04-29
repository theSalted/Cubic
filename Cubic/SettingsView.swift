//
//  SettingsView.swift
//  Object Capture
//
//  Created by Yuhao Chen on 4/25/22.
//

import SwiftUI

struct SettingsView: View {
    
    var featureSensitivity = ["Normal", "High"]
    var sampleOrdering = ["Unordered", "Sequential"]
    
    @Binding var sensitivity: String
    @Binding var ordering: String
    @Binding var enableMasking: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Feature Sensitivity", selection: $sensitivity) {
                ForEach(featureSensitivity, id: \.self) {
                    Text($0)
                }
            }
            Picker("Sample Ordering", selection: $ordering) {
                ForEach(sampleOrdering, id: \.self) {
                    Text($0)
                }
            }
            Toggle(isOn: $enableMasking) {
                Text("Enable Mask")
            }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(sensitivity: .constant("Normal"), ordering: .constant("Unordered"), enableMasking: .constant(true))
    }
}
