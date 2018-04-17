//
//  ViewController.swift
//  DesktopBuddy
//
//  Created by Duncan MacDonald on 4/13/18.
//  Copyright © 2018 Duncan MacDonald. All rights reserved.
//

import UIKit
import AWSIoT
import SwiftyJSON

let thingName = "RaspPi"

class ViewController: UIViewController {
    
    var connected = false

    var dataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    
    var awsLink: IoTManager!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var gifTextField: UITextField!
    @IBOutlet weak var zipCodeTextField: UITextField!
    @IBOutlet weak var unitSegmentedControl: UISegmentedControl!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBAction func connectButtonTapped(_ sender: UIButton) {
        if !connected {
            awsLink.connect()
            self.connected = true
        } else {
            awsLink.disconnect()
            self.connected = false
        }
    }

    @IBAction func sendButtonTapped(_ sender: Any) {
        awsLink.showGif(gifName: gifTextField.text!)
    }

    @IBAction func clockButtonTapped(_ sender: Any) {
        let unit = unitSegmentedControl.titleForSegment(at: unitSegmentedControl.selectedSegmentIndex)
        let region = "US/Pacific"
        let zipCode = zipCodeTextField.text
        
        awsLink.showClock(unit: unit!, zip_code: zipCode!, region: region, tempColor: RGBColor.green(), dayColor: RGBColor.red(), dateColor: RGBColor.blue(), hourColor: RGBColor.cyan(), minuteColor: RGBColor.yellow())
    }

    func showConfirmation() {
        self.showAlert(title: "Sent", message: "Command sent", actionText: "Dismiss")
    }
    
    override func viewDidLoad() {
        awsLink = IoTManager()
        
        awsLink.delegate = self
    }
}

extension ViewController: IoTManagerDelegate {
    func IoTManagerChangedState(sender: IoTManager, didChangeState: AWSIoTMQTTStatus) {
        print("CHANGED STATE")
        switch didChangeState {
        case .connected:
            statusLabel.text = "Connected"
            
            connected = true
            
            connectButton.setTitle("disconnect", for: .normal)
        case .disconnected:
            statusLabel.text = "Disconnected"
            
            self.connected = false
            
            connectButton.setTitle("connect", for: .normal)
        case .connecting:
            statusLabel.text = "Connecting..."
        case .connectionError:
            statusLabel.text = "Connection Error"
        case .connectionRefused:
            statusLabel.text = "Connection Refused"
        default:
            statusLabel.text = "Unknown Error"
        }
    }
}


