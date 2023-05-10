// Developed by Ben Dodson (ben@bendodson.com)

import SwiftUI
import DeviceDiscoveryUI

struct ContentView: View {
    
    
    
    @ObservedObject private var deviceManager = LocalDeviceManager(applicationService: "remote", didReceiveMessage: { data in
        guard let string = String(data: data, encoding: .utf8) else { return }
        NSLog("Message: \(string)")
    }, errorHandler: { error in
        NSLog("ERROR: \(error)")
    })
    
    @State private var showDevicePicker = false
    
    var body: some View {
        VStack {
            
            if deviceManager.isConnected {
                Button("Send") {
                    deviceManager.send("Hello from tvOS!")
                }
                
                Button("Disconnect") {
                    deviceManager.disconnect()
                }
            } else {
                DevicePicker(.applicationService(name: "remote")) { endpoint in
                    deviceManager.connect(to: endpoint)
                } label: {
                    Text("Connect to a local device.")
                } fallback: {
                    Text("Device browsing is not supported on this device")
                } parameters: {
                    .applicationService
                }
            }
                
        }
        .padding()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
