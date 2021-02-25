//
//  iotClientViewController.swift
//  cSDKonIOS
//
//  Created by Dane Walton on 2/23/21.
//

import Foundation
import AzureIoTHubClient

class sIotHubClient: ObservableObject {
    
    private var iothub: String = ""
    private var deviceId: String = ""
    private var sasKey: String = ""
    
    private var connectionString: String = ""
    
    private(set) var numReceivedMessages: Int = 0
    
    @Published private(set) var numSentMessages: Int = 0
    @Published private(set) var numSentMessagesGood: Int = 0
    @Published private(set) var numSentMessagesBad: Int = 0
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isSendingTelemetry: Bool = false
    
    private(set) var lastTempValue : String = ""
    private(set) var lastHumidityValue : String = ""
    @Published private(set) var telemetryMessage : String = ""
    
    // Timers used to control message and polling rates
    var timerMsgRate: Timer!
    var timerDoWork: Timer!
    
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
    
    private func incSentMessagesGood() {
        numSentMessagesGood += 1
    }
    
    private func incSentMessagesBad() {
        numSentMessagesBad += 1
    }
    
    private func createTelemetryMessage() -> String {
        let temperature = String(format: "%.2f",drand48() * 15 + 20)
        let humidity = String(format: "%.2f", drand48() * 20 + 60)
        let data : [String : String] = ["temperature":temperature,
                                    "humidity": humidity]
        lastTempValue = data["temperature"]!
        lastHumidityValue = data["humidity"]!
        
        return data.description
    }
    
    /// Sends a message to the IoT hub
    @objc private func sendMessage() {

        // This the message
        telemetryMessage = createTelemetryMessage()
        
        
        // Construct the message
        let messageHandle: IOTHUB_MESSAGE_HANDLE = IoTHubMessage_CreateFromByteArray(telemetryMessage, telemetryMessage.utf8.count)
        
        if (messageHandle != OpaquePointer.init(bitPattern: 0)) {
            
            // Manipulate my self pointer so that the callback can access the class instance
            let that = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            
            print("Send a message")
            if (IOTHUB_CLIENT_OK == IoTHubClient_LL_SendEventAsync(iotHubClientHandle, messageHandle, mySendConfirmationCallback, that)) {
                numSentMessages += 1
            }
        }
    }
    
    @objc private func doWork() {
        print("Doing work")
        IoTHubClient_LL_DoWork(iotHubClientHandle)
    }
    
    let myConnectionStatusCallback: IOTHUB_CLIENT_CONNECTION_STATUS_CALLBACK = { result, reason, context in
        
        var mySelf: sIotHubClient = Unmanaged<sIotHubClient>.fromOpaque(context!).takeUnretainedValue()
        
        if (result == IOTHUB_CLIENT_CONNECTION_AUTHENTICATED) {
            mySelf.isConnected = true;
        }
    }
    
    // This function will be called when a message confirmation is received
    //
    // This is a variable that contains a function which causes the code to be out of the class instance's
    // scope. In order to interact with the UI class instance address is passed in userContext. It is
    // somewhat of a machination to convert the UnsafeMutableRawPointer back to a class instance
    let mySendConfirmationCallback: IOTHUB_CLIENT_EVENT_CONFIRMATION_CALLBACK = { result, userContext in
        
        var mySelf: sIotHubClient = Unmanaged<sIotHubClient>.fromOpaque(userContext!).takeUnretainedValue()
        
        if (result == IOTHUB_CLIENT_CONFIRMATION_OK) {
            mySelf.incSentMessagesGood()
        }
        else {
            mySelf.incSentMessagesBad()
        }
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
        print("Creating from Connection String")
        iotHubClientHandle = IoTHubClient_LL_CreateFromConnectionString(connectionString, iotProtocol)
        
        // This gets an unmanaged and unretained pointer to the self object. We then pass it to the callback.
        // Note: Unmanaged means do away with reference counting. Unretained means we don't have to release usage.
        // Note: UnsafeMutableRawPointer is changeable and does away with Swift memory safety features (like C).
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        if (IOTHUB_CLIENT_OK != (IoTHubClient_LL_SetConnectionStatusCallback(iotHubClientHandle, myConnectionStatusCallback, selfPointer))) {
            print("There was a problem setting the connection callback")
            return
        }
        
        // Set up the message callback
        if (IOTHUB_CLIENT_OK != (IoTHubClient_LL_SetMessageCallback(iotHubClientHandle, myReceiveMessageCallback, selfPointer))) {
            print("There was a problem setting the message callback ")
            return
        }
        
        timerDoWork = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(doWork), userInfo: nil, repeats: true)
    }
    
    func disconectFromIoTHub() {
        stopSendTelemetryMessages()
        timerDoWork.invalidate()
        IoTHubClient_LL_Destroy(iotHubClientHandle)
        isConnected = false
    }
    
    func startSendTelemetryMessages() {
        // Timer for message sends and timer for message polls
        if(isConnected)
        {
            isSendingTelemetry = true
            timerMsgRate = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(sendMessage), userInfo: nil, repeats: true)
        }
    }
    
    func stopSendTelemetryMessages() {
        isSendingTelemetry = false
        if(timerMsgRate.isValid) {
            timerMsgRate.invalidate()
        }
    }
}
