//
//  ContentView.swift
//  Taskii
//
//  Created by Jaron Durkee on 3/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack{
            Image(systemName: "checkmark")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Welcome to Taskii!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
