//
//  ContentView.swift
//  Sandbox
//
//  Created by Dane Walton on 2/22/21.
//

import SwiftUI

private var myConnectionString: String = ""

struct ContentView: View {
    @State var isSendingTelemetry = false
    @State var isSendingTelemetryButtonText: String = "Start"
    @State var methodName = "nil"
    
    var myHubClient = sIotHubClient(connectionString: myConnectionString)
    
    var body: some View {
        VStack {
            HStack {
                Text("C SDK on iOS")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(/*@START_MENU_TOKEN@*/Color(hue: 0.66, saturation: 0.97, brightness: 0.664)/*@END_MENU_TOKEN@*/)
                    .padding()
                Spacer()
            }
            Divider()
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
                    myHubClient.connectToIoTHub()
                }, label: {
                    Text("Connect")
                }).padding()
            }
            Divider()
            HStack {
                Text("Send Telemetry").padding()
                Spacer()
                Button(action: {
                    if(isSendingTelemetry) {
                        isSendingTelemetryButtonText = "Start"
                        isSendingTelemetry = false
                    }
                    else {
                        isSendingTelemetryButtonText = "Stop"
                        isSendingTelemetry = true
                    }
                    print("\(isSendingTelemetryButtonText)")
                }, label: {
                    Text("\(isSendingTelemetryButtonText)")
                }).padding()
            }
            HStack {
                Text("Latest Method").padding()
                Spacer()
                Text("\(methodName)").padding()
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
