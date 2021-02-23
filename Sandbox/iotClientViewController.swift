//
//  iotClientViewController.swift
//  Sandbox
//
//  Created by Dane Walton on 2/23/21.
//

import Foundation
import AzureIoTHubClient

class sIotHubClient {
    
    private var iothub: String = ""
    private var deviceId: String = ""
    private var sasKey: String = ""
    
    private var connectionString: String = ""
    
    private(set) var numReceivedMessages: Int = 0
    
    // IoT hub handle
    private var iotHubClientHandle: IOTHUB_CLIENT_LL_HANDLE!
    
    //Protocol of choice to connect
    private let iotProtocol: IOTHUB_CLIENT_TRANSPORT_PROVIDER = MQTT_Protocol
    
    init(iothub: String, deviceId: String, sasKey: String) {
        self.iothub = iothub
        self.deviceId = deviceId
        self.sasKey = sasKey
    }
    
    init(connectionString: String) {
        self.connectionString = connectionString
    }
    
    private func connectionStringCreateFromSAS() -> String {
        return "HostName=\(iothub);DeviceId=\(deviceId);SharedAccessKey=\(sasKey)"
    }
    
    private func incReceivedMessage() {
        numReceivedMessages += 1
    }
    
    // Note: This is the syntax for an anonymous function. Paremeters go inside the curly braces
    // instead of outside. The keyword `in` declares the beginning of the body of the closure.
    // We are creating the function and assigning it to a variable instead of declaring the function by itself.
    let myReceiveMessageCallback: IOTHUB_CLIENT_MESSAGE_CALLBACK_ASYNC = {
        (message, userContext) -> (IOTHUBMESSAGE_DISPOSITION_RESULT) in
        
        // Cast the context which is `self`
        var mySelf: sIotHubClient = Unmanaged<sIotHubClient>.fromOpaque(userContext!).takeUnretainedValue()

        var messageId: String! = nil
        var correlationId: String! = nil
        var size: Int = 0
        var buff: UnsafePointer<UInt8>?
        var messageString: String = ""
        
        messageId = String(describing: IoTHubMessage_GetMessageId(message))
        correlationId = String(describing: IoTHubMessage_GetCorrelationId(message))
        
        if (messageId == nil) {
            messageId = "<nil>"
        }
        
        if correlationId == nil {
            correlationId = "<nil>"
        }
        
        mySelf.incReceivedMessage()
        
        // Get the data from the message
        var rc: IOTHUB_MESSAGE_RESULT = IoTHubMessage_GetByteArray(message, &buff, &size)
        
        if rc == IOTHUB_MESSAGE_OK {
            print("I got a message")
        }
        
        return IOTHUBMESSAGE_ACCEPTED
    }
    
    //Connect the device to iothub
    func connectToIoTHub() {
        
        if(connectionString.isEmpty)
        {
            connectionString = connectionStringCreateFromSAS()
        }
        
        // Create the client handle
        iotHubClientHandle = IoTHubClient_LL_CreateFromConnectionString(connectionString, iotProtocol)
        
        // This gets an unmanaged and unretained pointer to the self object. We then pass it to the callback.
        // Note: Unmanaged means do away with reference counting. Unretained means we don't have to release usage.
        // Note: UnsafeMutableRawPointer is changeable and does away with Swift memory safety features (like C).
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // Set up the message callback
        if (IOTHUB_CLIENT_OK != (IoTHubClient_LL_SetMessageCallback(iotHubClientHandle, myReceiveMessageCallback, selfPointer))) {
            print("There was a problem setting the callback ")
            
            return
        }
    }
}
