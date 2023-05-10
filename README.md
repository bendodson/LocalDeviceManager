# LocalDeviceManager
Using `DeviceDiscoveryUI` to connect an Apple TV app to an iPhone, iPad, or Apple Watch.

## Limitations of DeviceDiscoveryUI
- Only runs on Apple TV 4K currently (Apple TV HD is not supported)
- The tvOS app can only connect to one device at a time (i.e. you couldn’t make a game with this that used two iPhones as controllers)
- The tvOS app can only connect to other versions of your app that share the same bundle identifier (and are thus sold with [Universal Purchase](https://developer.apple.com/support/universal-purchase/))
- This will not work on either the tvOS or iOS simulators. You must use physical devices.

## Usage
There are a few steps you need to run through in order to communicate between Apple TV and another device (I'll use an iPhone for all examples but the same code would apply to iPad or Apple Watch).

### Apple TV

#### Step 1.
Define supported devices with an [NSApplicationServices key](https://developer.apple.com/documentation/devicediscoveryui/connecting_a_tvos_app_to_other_devices_over_the_local_network#3976721) in your Info.plist

#### Step 2.
Instantiate the `LocalDeviceManager` using the application service key you defined in Step 1 (i.e. "remote" in this example):

```
@ObservedObject private var deviceManager = LocalDeviceManager(applicationService: "remote", didReceiveMessage: { data in
    guard let string = String(data: data, encoding: .utf8) else { return }
    NSLog("Message: \(string)")
}, errorHandler: { error in
    NSLog("ERROR: \(error)")
})
```

The `LocalDeviceManager` has a callback for when messages are received. You have access to the raw `Data` but I would suggest you only send encoded strings rather than custom models in case the packets are delivered in chunks.

An error handler is also provided in case of failures.

#### Step 3.
Present the Device Picker UI. This demo uses SwiftUI but you can use [`DDDevicePickerViewController`](https://developer.apple.com/documentation/devicediscoveryui/dddevicepickerviewcontroller) in UIKit.

```
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
```

This will present the native device picker. Upon selecting a device, a notification will be sent asking the user to either download the app or open the app if installed. Once they do this, the connection will be established.

![Notifications from the tvOS Device Picker](https://bendodson.s3-eu-west-1.amazonaws.com/weblog/2023/DevicePicker-Notifications-iOS.jpg)


### iPhone / iPad / Apple Watch

#### Step 1.
Declare the device can listen for connections by using an [NSApplicationServices key](https://developer.apple.com/documentation/devicediscoveryui/connecting_a_tvos_app_to_other_devices_over_the_local_network#3986063) in your Info.plist

#### Step 2.
Instantiate the `LocalDeviceManager` using the application service key you defined in Step 1 (i.e. "remote" in this example):

```
@ObservedObject private var deviceManager = LocalDeviceManager(applicationService: "remote", didReceiveMessage: { data in
    guard let string = String(data: data, encoding: .utf8) else { return }
    NSLog("Message: \(string)")
}, errorHandler: { error in
    NSLog("ERROR: \(error)")
})
```

This is identical to the tvOS implementation.

#### Step 3.
Create your UI and ensure that the `LocalDeviceManager` listener is created as soon as possible.

```
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
```

You can now send data from tvOS to your connected device and vice versa.

## Find Out More
You can read [my blog post](https://bendodson.com/weblog/2023/05/10/connecting-a-tvos-app-to-ios-ipados-and-watchos-with-devicediscoveryui/) on this topic to learn more about DeviceDiscoveryUI in tvOS 16 and how I'm using this class in my own apps.
