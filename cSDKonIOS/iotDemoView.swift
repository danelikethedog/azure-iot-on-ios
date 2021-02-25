//
//  iotDemoView.swift
//  cSDKonIOS
//
//  Created by Dane Walton on 2/22/21.
//

import SwiftUI

private var myConnectionString: String = ""

struct iotDemoView: View {
    @ObservedObject var myHubClient = sIotHubClient(connectionString: myConnectionString)
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("Azure C SDK on iOS")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(/*@START_MENU_TOKEN@*/Color(hue: 0.66, saturation: 0.97, brightness: 0.664)/*@END_MENU_TOKEN@*/)
                        .padding()
                    Spacer()
                }
                Divider()
                authenticationItems(hubClient: myHubClient)
                Divider()
                metricsItems(hubClient: myHubClient)
                Divider()
                Spacer()
            }
        }
    }
}

struct authenticationItems: View {
    @ObservedObject var hubClient: sIotHubClient
    var body: some View {
        HStack {
            Text("Scan for SAS Key").padding()
            Spacer()
            Button(action: {
                print("Scan selected")
            }, label: {
                Text("Scan")
            }).padding()
        }
        Divider()
        HStack {
            Text("Connect to IoT Hub").padding()
            Spacer()
            Button(action: {
                if(hubClient.isConnected)
                {
                    hubClient.disconectFromIoTHub()
                } else {
                    hubClient.connectToIoTHub()
                }
            }, label: {
                if(hubClient.isConnected)
                {
                    Text("Disconnect")
                } else {
                    Text("Connect")
                }
            }).padding()
        }
        HStack {
            Text("Connection Status").padding()
            Spacer()
            if(hubClient.isConnected) {
                Text("Connected").foregroundColor(Color.green).padding()
            } else {
                Text("Disconnected").foregroundColor(Color.red).padding()
            }
        }
    }
}

struct metricsItems: View {
    @State private var isSendingTelemetryButtonText: String = "Start"
    @State private var methodName = "nil"
    
    @ObservedObject var hubClient: sIotHubClient

    var body: some View {
        HStack {
            Text("Send Telemetry").padding()
            Spacer()
            Button(action: {
                if(hubClient.isSendingTelemetry) {
                    isSendingTelemetryButtonText = "Start"
                    hubClient.stopSendTelemetryMessages()
                }
                else {
                    isSendingTelemetryButtonText = "Stop"
                    hubClient.startSendTelemetryMessages()
                }
                print("\(isSendingTelemetryButtonText)")
            }, label: {
                Text("\(isSendingTelemetryButtonText)")
            }).padding()
        }
        HStack {
            Text("Last Sent Message").padding()
            Spacer()
            Text("<\(hubClient.telemetryMessage)>").padding()
        }
        HStack {
            Text("Messages Sent").padding()
            Spacer()
            VStack {
                Text("Sent")
                Text("\(hubClient.numSentMessages)")
            }.padding()
            VStack {
                Text("+")
                    .foregroundColor(Color.green)
                Text("\(hubClient.numSentMessagesGood)")
                    .foregroundColor(Color.green)
            }.padding()
            VStack {
                Text("-")
                    .foregroundColor(Color.red)
                Text("\(hubClient.numSentMessagesBad)")
                    .foregroundColor(Color.red)
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        iotDemoView()
    }
}
