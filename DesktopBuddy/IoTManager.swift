//
//  AWSHelper.swift
//  DesktopBuddy
//
//  Created by Duncan MacDonald on 4/16/18.
//  Copyright © 2018 Duncan MacDonald. All rights reserved.
//

import Foundation
import AWSIoT
import SwiftyJSON

protocol IoTManagerDelegate: class {
    func IoTManagerChangedState(sender: IoTManager, didChangeState: AWSIoTMQTTStatus)
}

class IoTManager {
    var isConnected = false
    
    var dataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    
    var topic = "rpi/desktopbuddy"
    
    weak var delegate: IoTManagerDelegate!
    
    init() {
        print("initializing")
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: CognitoIdentityPoolId)
        let iotEndpoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        let iotConfiguration = AWSServiceConfiguration(region: .USWest2, endpoint: iotEndpoint, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = iotConfiguration
        
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
        
        AWSIoTDataManager.register(with: iotConfiguration!, forKey: "a key")
        dataManager = AWSIoTDataManager(forKey: "a key")
    }
    
    func connect() {
        if !self.isConnected {
            print("Attempting to connect...")
            
            self.configureCertificate()
        }
    }
    
    func disconnect() {
        if self.isConnected {
            self.dataManager.disconnect()
        }
    }
    
    func mqttEventCallback(_ status: AWSIoTMQTTStatus) {
        DispatchQueue.main.async {
                print("MQTT Connection Status: \(status.rawValue)")
            
            switch status {
            case .connecting:
                print("Connecting...")
            case .connected:
                print("Connected")
                self.isConnected = true
                
                let uuid = UUID().uuidString
                let defaults = UserDefaults.standard
                let certificateId = defaults.string(forKey: "certificateId")
                
                print("Using certificate: \n\(certificateId)\nClient ID:\n\(uuid)")
            case .disconnected:
                print("Disconnected")
            case .connectionRefused:
                print("Connection Refused")
            case .connectionError:
                print("Connection Error")
            case .protocolError:
                print("Protocol Error")
            default:
                print("Unknown State")
            }
            
            self.delegate?.IoTManagerChangedState(sender: self, didChangeState: status)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "connectionStatusChanged"), object: self)
        }
    }
    
    func configureCertificate() {
        let defaults = UserDefaults.standard
        var certificateId = defaults.string(forKey: "certificateId")
        
        if certificateId == nil {
            DispatchQueue.main.async {
                print("No identity found, searching bundle")
            }
            
            let myBundle = Bundle.main
            let myFiles = myBundle.paths(forResourcesOfType: "p12", inDirectory: nil)
            let uuid = UUID().uuidString
            
            if myFiles.count > 0 {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: myFiles[0])) {
                    print("Found identity, importing..")
                    
                    if AWSIoTManager.importIdentity(fromPKCS12Data: data, passPhrase: "", certificateId: myFiles[0]) {
                        defaults.set(myFiles[0], forKey: "certificateId")
                        defaults.set("from-bundle", forKey: "certificateArn")
                        
                        print("Using certificate: \(myFiles[0])")
                        self.dataManager.connect(withClientId: uuid, cleanSession: true, certificateId: myFiles[0], statusCallback: mqttEventCallback)
                    }
                }
            }
            certificateId = defaults.string(forKey: "certificateId")
        } else {
            let uuid = UUID().uuidString
            
            dataManager.connect(withClientId: uuid, cleanSession: true, certificateId: certificateId!, statusCallback: mqttEventCallback)
            
            self.isConnected = false
        }
    }
    
    func showGif(gifName: String) {
        let js: JSON = ["message": "gif",
                        "args": gifName]
        
        var data: Data!
        
        do {
            data = try js.rawData()
        } catch {
            print("Error converting JSON to rawData")
        }
        
        dataManager.publishData(data, onTopic: topic, qoS: AWSIoTMQTTQoS(rawValue: 1)!)
    }
    
    func showClock(unit: String="f", zip_code: String="94103", region: String="US/Pacific", tempColor: RGBColor, dayColor: RGBColor, dateColor: RGBColor, hourColor: RGBColor, minuteColor: RGBColor) {
        let js: JSON = ["message": "clock",
                        "args": [
                            "unit": unit,
                            "zip_code": zip_code,
                            "region": region,
                            "temp_color": tempColor.asJson(),
                            "day_color": dayColor.asJson(),
                            "date_color": dateColor.asJson(),
                            "hour_color": hourColor.asJson(),
                            "minute_color": minuteColor.asJson()]]
        
        var data: Data!
        
        do {
            data = try js.rawData()
        } catch {
            print("Error converting JSON to rawData")
        }
        
        dataManager.publishData(data, onTopic: topic, qoS: AWSIoTMQTTQoS(rawValue: 1)!)
    }
}

struct RGBColor {
    var r: Int!
    var g: Int!
    var b: Int!
    
    init(_ r: Int, _ g: Int, _ b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    func asJson() -> JSON {
        let js: JSON = ["r": self.r,
                        "g": self.g,
                        "b": self.b]
        
        return js
    }
    
    static func red() -> RGBColor {
        return RGBColor(255, 0, 0)
    }
    
    static func green() -> RGBColor {
        return RGBColor(0, 255, 0)
    }
    
    static func blue() -> RGBColor {
        return RGBColor(0, 0, 255)
    }
    
    static func cyan() -> RGBColor {
        return RGBColor(0, 255, 255)
    }
    
    static func yellow() -> RGBColor {
        return RGBColor(255, 255, 0)
    }
    
    static func magenta() -> RGBColor {
        return RGBColor(255, 0, 255)
    }
    
    static func orange() -> RGBColor {
        return RGBColor(255, 127, 0)
    }
    
    static func purple() -> RGBColor {
        return RGBColor(127, 0, 127)
    }
}
