//
//  Device.swift
//  BLEConnect
//
//  Created by Evan Stone on 8/15/16.
//  Copyright © 2016 Cloud City. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Device {
    
    // UUIDs
    // Apple Service: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
    // Apple Characteristic: "08590F7E-DB05-467E-8757-72F6FAEB13D4"
    /*#define RBL_SERVICE_UUID                         "713D0000-503E-4C75-BA94-3148F18D941E"
     #define RBL_CHAR_TX_UUID                         "713D0002-503E-4C75-BA94-3148F18D941E"
     #define RBL_CHAR_RX_UUID                         "713D0003-503E-4C75-BA94-3148F18D941E"*/
   /* static let TransferService = "E71EE188-279F-4ED6-8055-12D77BFD900C"
    static let TransferCharacteristic = "2F016955-E675-49A6-9176-111E2A1CF333"*/
    
    static let TransferService = "713D0000-503E-4C75-BA94-3148F18D941E"
    static let TransferCharacteristic = "713D0002-503E-4C75-BA94-3148F18D941E"
    
    static let TRACKERSERVICETX = "713D0002-503E-4C75-BA94-3148F18D941E"
    static let TRACKERSERVICERX = "713D0003-503E-4C75-BA94-3148F18D941E"
    static let TRACKERRAWDATA = "713D0004-503E-4C75-BA94-3148F18D941E"
    
    // Tags
    static let EOM = "{{{EOM}}}"
    
    // We have a 20-byte limit for data transfer
    static let notifyMTU = 20
    
    static let centralRestoreIdentifier = "io.cloudcity.BLEConnect.CentralManager"
    static let peripheralRestoreIdentifier = "io.cloudcity.BLEConnect.PeripheralManager"
}
