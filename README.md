# Azure IoT on iOS

This is a basic sample which will connect to Azure IoT Hub using the [Azure IoT C SDK](https://github.com/Azure/azure-iot-sdk-c).

## Steps to get working

1. Make sure `pod` is installed on your machine.
1. From the root of the project, run pod install.
1. Open the `cSDKonIOS.xcworkspace` in XCode.
1. Change the connection string [here](https://github.com/danelikethedog/azure-iot-on-ios/blob/f8d5f427a0b85744909314646613a7f25c795d37/cSDKonIOS/iotDemoView.swift#L10) to your device.
1. Build and run the sample!

### Picture of the Screen

![img](./img/screendemo.jpg){:height="50%" width="50%"}

## Project Notes
- This is built with SwiftUI which means iOS minimum version iOS 13.

## Still to Do
- Add OCR functionality to scan the connection string in the app so users don't have to input.