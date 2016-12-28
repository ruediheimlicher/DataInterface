//
//  DataViewController.swift
//  DataInterface
//
//  Created by Ruedi Heimlicher on 28.12.2016.
//  Copyright © 2016 Ruedi Heimlicher. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation
import Darwin
import AudioToolbox

let TEENSYPRESENT   =   7

// USB Eingang
// Temperatur
let DSLO = 8
let DSHI = 9

// ADC
let  ADCLO      =      10
let  ADCHI      =      11

// USB Ausgang
let SERVOALO = 10
let SERVOAHI = 11

let MMCLO = 16
let MMCHI = 17


// Task
let WRITE_MMC_TEST  =   0xF1

// Bytes fuer Sicherungsort der Daten auf SD

let MESSUNG_START   =   0xC0 // Start der Messreihe
let MESSUNG_STOP   =   0xC1 // Start der Messreihe


let SAVE_SD_RUN = 0x02 // Bit 1
let SAVE_SD_STOP = 0x04 // Bit 2

let SAVE_SD_BYTE          =     1 //

let ABSCHNITT_BYTE   =     2 // Abschnitt auf SD

let BLOCKOFFSETLO_BYTE    =     3 // Block auf SD fuer Sicherung
let BLOCKOFFSETHI_BYTE    =     4



let TAKT_LO_BYTE = 14
let TAKT_HI_BYTE = 15

let DATACOUNT_LO    =   12 // Messung, laufende Nummer
let DATACOUNT_HI    =   13


let DATA_START_BYTE   = 15    // erstes byte fuer Data

let LOGGER_START = 0xA0
let LOGGER_CONT = 0xA1

let LOGGER_STOP = 0xAF

let LOGGER_SETTING    =  0xB0 // Setzen der Settings fuer die Messungen
let LOGGER_DATA    =  0xB1 // Setzen der Settings fuer die Messungen

let USB_STOP    = 0xAA



class DataViewController: NSViewController, NSWindowDelegate, AVAudioPlayerDelegate
{
   
   // Variablen
   var usbstatus: __uint8_t = 0
   
   var usb_read_cont = false; // kontinuierlich lesen
   var usb_write_cont = false; // kontinuierlich schreiben
   
   // Logger lesen
   var startblock:UInt16 = 1 // Byte 1,2: block 1 ist formatierung
   var blockcount:UInt16 = 0 // Byte 3, 4: counter beim Lesen von mehreren Bloecken
   var packetcount :UInt8 = 0 // byte 5: counter fuer pakete beim Lesen eines Blocks 10 * 48 + 32
   
   var loggerDataArray:[[UInt8]] = [[]]
   var DiagrammDataArray:[[Float]] = [[]]

   var teensycode:UInt8 = 0
   
   var spistatus:UInt8 = 0;
   var DiagrammFeld:CGRect = CGRect.zero

   
   
   var swiftArray = [[String:AnyObject]]()

   @IBOutlet weak var save_SD_check: NSButton!
   @IBOutlet weak var Start_Messung: NSButton!
   
   @IBOutlet weak var manufactorer: NSTextField!
   @IBOutlet weak var Counter: NSTextField!
   
   @IBOutlet weak var Start: NSButton!
   
   @IBOutlet weak var inputDataFeldFeld: NSTextField!
   
   @IBOutlet weak var USB_OK: NSTextField!
   
   @IBOutlet weak var start_read_USB_Knopf: NSButton!
   @IBOutlet weak var stop_read_USB_Knopf: NSButton!
   @IBOutlet weak var cont_read_check: NSButton!
   
   @IBOutlet weak var start_write_USB_Knopf: NSButton!
   @IBOutlet weak var stop_write_USB_Knopf: NSButton!
   @IBOutlet weak var cont_write_check: NSButton!
   
   
   @IBOutlet weak var codeFeld: NSTextField!
   
   @IBOutlet weak var data0: NSTextField!
   
   @IBOutlet weak var data1: NSTextField!
   
   @IBOutlet  var inputDataFeld: NSTextView!
   
   @IBOutlet weak var write_sd_startblock: NSTextField!
   @IBOutlet weak var write_sd_anzahl: NSTextField!
   @IBOutlet weak var read_sd_startblock: NSTextField!
   @IBOutlet weak var read_sd_anzahl: NSTextField!
   
   @IBOutlet  var downloadDataFeld: NSTextView!
   
   
   @IBOutlet weak var data2: NSTextField!
   @IBOutlet weak var data3: NSTextField!
   
   
   @IBOutlet weak var H_Feld: NSTextField!
   
   @IBOutlet weak var L_Feld: NSTextField!
   
   @IBOutlet weak var spannungsanzeige: NSSlider!
   @IBOutlet weak var extspannungFeld: NSTextField!
   
   @IBOutlet weak var spL: NSTextField!
   @IBOutlet weak var spH: NSTextField!
   
   @IBOutlet weak var extstrom: NSTextField!
   @IBOutlet weak var Teensy_Status: NSButton!
   
   
   @IBOutlet weak var extspannungStepper: NSStepper!
   
   
   // Datum
   @IBOutlet weak var sec_Feld: NSTextField!
   @IBOutlet weak var min_Feld: NSTextField!
   @IBOutlet weak var std_Feld: NSTextField!
   @IBOutlet weak var wt_Feld: NSTextField!
   @IBOutlet weak var mon_Feld: NSTextField!
   @IBOutlet weak var jahr_Feld: NSTextField!
   @IBOutlet weak var datum_Feld: NSTextField!
   @IBOutlet weak var zeit_Feld: NSTextField!
   @IBOutlet weak var tagsec_Feld: NSTextField!
   @IBOutlet weak var tagmin_Feld: NSTextField!
   
   
   @IBOutlet weak var DSLO_Feld: NSTextField!
   @IBOutlet weak var DSHI_Feld: NSTextField!
   @IBOutlet weak var DSTempFeld: NSTextField!
   
   // ADC
   @IBOutlet weak var ADCLO_Feld: NSTextField!
   @IBOutlet weak var ADCHI_Feld: NSTextField!
   @IBOutlet weak var ADCFeld: NSTextField!
   
   @IBOutlet weak var ServoASlider: NSSlider!
   
   // Logging
   @IBOutlet weak var Start_Logger: NSButton!
   @IBOutlet weak var Stop_Logger: NSButton!
   
   
   // Einstellungen
   @IBOutlet weak var IntervallPop: NSComboBox!
   @IBOutlet weak  var TaskListe: NSTableView!
   @IBOutlet weak var Set_Settings: NSButton!
   
   // USB-code
   @IBOutlet weak var bit0_check: NSButton!
   @IBOutlet weak var bit1_check: NSButton!
   @IBOutlet weak var bit2_check: NSButton!
   @IBOutlet weak var bit3_check: NSButton!
   @IBOutlet weak var bit4_check: NSButton!
   @IBOutlet weak var bit5_check: NSButton!
   @IBOutlet weak var bit6_check: NSButton!
   @IBOutlet weak var bit7_check: NSButton!
   
   // mmc
   @IBOutlet weak var mmcLOFeld: NSTextField!
   @IBOutlet weak var mmcHIFeld: NSTextField!
   @IBOutlet weak var mmcDataFeld: NSTextField!



   
   @IBAction func SaveResBut(sender: AnyObject)
   {
      // https://eclecticlight.co/2016/12/23/more-fun-scripting-with-swift-and-xcode-alerts-and-file-save/
      let fileContentToWrite = inputDataFeld.string
      //and so on to build the text to be written out to the file
      let FS = NSSavePanel()
      FS.canCreateDirectories = true
      FS.allowedFileTypes = ["txt"]
      //which should also allow “txt”
      FS.begin { result in
         if result == NSFileHandlingPanelOKButton {
            guard let url = FS.url else { return }
            do {
               try fileContentToWrite?.write(to: url, atomically: false, encoding: String.Encoding.utf8)
            } catch {
               print (error.localizedDescription)
               //we should really have an error alert here instead
            }
         }
      }
   }

}
