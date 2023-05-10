// Developed by Ben Dodson (ben@bendodson.com)

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var deviceManager = LocalDeviceManager(applicationService: "remote", didReceiveMessage: { data in
        guard let string = String(data: data, encoding: .utf8) else { return }
        NSLog("Message: \(string)")
    }, errorHandler: { error in
        NSLog("ERROR: \(error)")
    })
    
    var body: some View {
        VStack {
            if deviceManager.isConnected {
                Text("Connected!")
                Button {
                    deviceManager.send("Hello from iOS!")
                } label: {
                    Text("Send")
                }
                Button {
                    deviceManager.disconnect()
                } label: {
                    Text("Disconnect")
                }

            } else {
                Text("Not Connected")
            }
        }
        .padding()
        .onAppear {
            try? deviceManager.createListener()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
