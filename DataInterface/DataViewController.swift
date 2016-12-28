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
   
   var teensy = usb_teensy()

   
   
   // Diagramm
   @IBOutlet  var datagraph: DataPlot!
   @IBOutlet  var dataScroller: NSScrollView!
   @IBOutlet  var dataAbszisse: Abszisse!


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
   
   
   open func writeData(name:String, data:String)
   {
      /*
       // http://www.techotopia.com/index.php/Working_with_Directories_in_Swift_on_iOS_8
       do {
       let filelist = try filemgr.contentsOfDirectory(atPath: "/")
       
       for filename in filelist {
       print(filename)
       }
       } catch let error {
       print("Error: \(error.localizedDescription)")
       }
       */
      //print ("\nwriteData data: \(data)")
      
      //http://stackoverflow.com/questions/24097826/read-and-write-data-from-text-file
      // http://www.techotopia.com/index.php/Working_with_Directories_in_Swift_on_iOS_8
      
      do
      {
         let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
         var datapfad = documentDirectoryURL.appendingPathComponent("LoggerdataDir")
         
         do
         {
            try FileManager.default.createDirectory(atPath: datapfad.path, withIntermediateDirectories: true, attributes: nil)
         }
         catch let error as NSError
         {
            print(error.localizedDescription);
         }
         
         
         print ("datapfad: \(datapfad)")
         
         datapfad = datapfad.appendingPathComponent(name)
         
         //writing
         do
         {
            try data.write(to: datapfad, atomically: false, encoding: String.Encoding.utf8)
         }
         catch let error as NSError
         {
            print(error.localizedDescription);
         }
      }
      catch
      {
         print("catch write")
      }
      
      return
      
      
      
      if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      {
         
         let path = dir.appendingPathComponent(data)
         
         //writing
         do
         {
            try data.write(to: path, atomically: false, encoding: String.Encoding.utf8)
         }
         catch {/* error handling here */}
         
         //reading
         do {
            let text2 = try String(contentsOf: path, encoding: String.Encoding.utf8)
            print("text2: \(text2)")
            inputDataFeld.string = text2
         }
         catch {/* error handling here */}
         
      }
   } // writeData
   
   
   
   
   func tagsekunde()-> Int
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      return 3600 * stunde + 60 * minute + sekunde
   }
   
   func datumstring()->String
   {
      let date = Date()
      let calendar = Calendar.current
      let jahr = calendar.component(.year, from: date)
      let tagdesmonats = calendar.component(.day, from: date)
      let monatdesjahres = calendar.component(.month, from: date)
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      formatter.dateFormat = "dd.MM.yyyy"
      let datumString = formatter.string(from: date)
      print("datumString: \(datumString)*")
      return datumString
   }
   
   func zeitstring()->String
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      let sekunde = calendar.component(.second, from: date)
      formatter.dateFormat = "hh:mm:ss"
      let zeitString = formatter.string(from: date)
      return zeitString
   }
   
   func datumprefix()->String
   {
      let date = Date()
      let calendar = Calendar.current
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "gsw-CH")
      
      let jahr = calendar.component(.year, from: date)
      let tagdesmonats = calendar.component(.day, from: date)
      let monatdesjahres = calendar.component(.month, from: date)
      let stunde = calendar.component(.hour, from: date)
      let minute = calendar.component(.minute, from: date)
      
      
      
      formatter.dateFormat = "yyMMdd_HHmm"
      let prefixString = formatter.string(from: date)
      return prefixString
   }
   
   func MessungDataString(data:[[Float]])-> String
   {
      var datastring:String = ""
      var datastringarray:[String] = []
      print("setMessungData: \(data)")
      for index in 0..<data.count
      {
         let tempzeilenarray:[Float] = data[index]
         if (tempzeilenarray.count > 0)
         {
            
            let tempzeilenstring = tempzeilenarray.map{String($0)}.joined(separator: "\t")
            datastringarray.append(tempzeilenstring)
            datastring = datastring +  "\n" + tempzeilenstring
         }
      }
      let prefix = datumprefix()
      let dataname = prefix + "_messungdump.txt"
      
      //      writeData(name: dataname,data:datastring)
      
      
      return datastring
   }
   



  //MARK: - Konfig Messung
   @IBAction func reportSetSettings(_ sender: NSButton)
   {
      print("reportSetSettings")
      print("\(swiftArray)")
      teensy.write_byteArray[0] = UInt8(LOGGER_SETTING)
      //Task lesen
      
      let save_SD = save_SD_check?.state
      var loggersettings:UInt8 = 0
      if ((save_SD == 1)) // Daten auf SD sichern
      {
         loggersettings = loggersettings | 0x01 // Bit 0
         
      }
      
      teensy.write_byteArray[SAVE_SD_BYTE] = loggersettings
      //Intervall lesen
      let selectedItem = IntervallPop.indexOfSelectedItem
      let intervallwert = IntervallPop .intValue
      // Taktintervall in array einsetzen
      teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(intervallwert & 0x00FF)
      teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((intervallwert & 0xFF00)>>8)
      //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
      // Abschnitt auf SD
      teensy.write_byteArray[ABSCHNITT_BYTE] = 0
      
      
      //Angabe zum  Startblock lesen. default ist 0
      let startblock = write_sd_startblock.integerValue
      teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
      teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
      
      
      let senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Glass")?.play()
      }
      
      
   }

   @IBAction func reportTaskIntervall(_ sender: NSComboBox)
   {
      print("reportTaskIntervall index: \(sender.indexOfSelectedItem)")
      if (sender.indexOfSelectedItem >= 0)
      {
         let wahl = sender.objectValueOfSelectedItem! as! String
         let index = sender.indexOfSelectedItem
         // print("reportTaskIntervall wahl: \(wahl) index: \(index)")
         // http://stackoverflow.com/questions/24115141/swift-converting-string-to-int
         let integerwahl:UInt16? = UInt16(wahl)
         print("reportTaskIntervall integerwahl: \(integerwahl!)")
         
         if let integerwahl = UInt16(wahl)
         {
            print("By optional binding :", integerwahl) // 20
         }
         
         //et num:Int? = Int(firstTextField.text!);
         // Taktintervall in array einsetzen
         teensy.write_byteArray[TAKT_LO_BYTE] = UInt8(integerwahl! & 0x00FF)
         teensy.write_byteArray[TAKT_HI_BYTE] = UInt8((integerwahl! & 0xFF00)>>8)
         //    print("reportTaskIntervall teensy.write_byteArray[TAKT_LO_BYTE]: \(teensy.write_byteArray[TAKT_LO_BYTE])")
      }
   }
   
   @IBAction func reportTaskListe(_ sender: NSTableView)
   {
      //print("reportTaskListe index: \(sender.selectedColumn)")
      
   }
   
   @IBAction func reportTaskCheck(_ sender: NSButton)
   {
      //print("reportTaskCheck state: \(sender.state)")
      //let zeile = TaskListe.selectedRow
      //var zelle = swiftArray[TaskListe.selectedRow] //as! [String:AnyObject]
      
      // let check = zelle["task"] as! Int
      // if (check == 0)
      
      if (swiftArray[TaskListe.selectedRow]["task"] as! Int == 1)
      {
         swiftArray[TaskListe.selectedRow]["task"] = 0  as AnyObject?
      }
      else
      {
         //zelle["task"] = 0 as AnyObject?
         swiftArray[TaskListe.selectedRow]["task"] = 1  as AnyObject?
      }
   }

   @IBAction func report_start_messung(_ sender: NSButton)
   {
      print("start_messung sender: \(sender.state)") // gibt neuen State an
      if (sender.state == 1)
      {
         print("start_messung start")
         teensy.write_byteArray[0] = UInt8(MESSUNG_START)
         
         teensy.write_byteArray[1] = UInt8(SAVE_SD_RUN)
         // Abschnitt auf SD
         teensy.write_byteArray[ABSCHNITT_BYTE] = 0
         
         //Angabe zum  Startblock lesen. default ist 0
         let startblock = write_sd_startblock.integerValue
         teensy.write_byteArray[BLOCKOFFSETLO_BYTE] = UInt8(startblock & 0x00FF) // Startblock
         teensy.write_byteArray[BLOCKOFFSETHI_BYTE] = UInt8((startblock & 0xFF00)>>8)
         let zeit = tagsekunde()
         print("start_messung zeit: \(zeit)")
         inputDataFeld.string = "Messung tagsekunde: \(zeit)\n"
         Counter.intValue = 0
      }
      else
      {
         print("start_messung stop")
         teensy.write_byteArray[0] = UInt8(MESSUNG_STOP)
         teensy.write_byteArray[1] = UInt8(SAVE_SD_STOP)
         
         teensy.read_OK = false
         usb_read_cont = false
         cont_read_check.state = 0;
         
         print("DiagrammDataArray: \(DiagrammDataArray)")
         
         let messungstring:String = MessungDataString(data:DiagrammDataArray)
         
         let prefix = datumprefix()
         let dataname = prefix + "_messungdump.txt"
         
         writeData(name: dataname,data:messungstring)
         
         //   let MessungDataString = DiagrammDataArray.map{String($0)}.joined(separator: "\n")
         /*
          print("messungstring: \(messungstring)\n")
          let erfolg = saveData(data: messungstring)
          if (erfolg == 0)
          {
          print("MessData sichern OK")
          NSSound(named: "Glass")?.play()
          }
          else
          {
          print("MessData sichern misslungen")
          
          }
          */
      }
      
      var senderfolg = teensy.start_write_USB()
      if (senderfolg > 0)
      {
         NSSound(named: "Glass")?.play()
      }
      
   }

   
   @IBAction func report_cont_write(_ sender: AnyObject)
   {
      NSSound(named: "Glass")?.play()
      
      if (sender.state == 0)
      {
         usb_write_cont = false
      }
      else
      {
         usb_write_cont = true
      }
      //println("report_cont_write usb_write_cont: \(usb_write_cont)")
   }
   
   
   @IBAction func report_cont_read(_ sender: AnyObject)
   {
      //audioPlayer.play()
      NSSound(named: "Glass")?.play()
      let systemSoundID: SystemSoundID = 1016
      AudioServicesPlaySystemSound (systemSoundID)
      if (sender.state == 0)
      {
         usb_read_cont = false
      }
      else
      {
         usb_read_cont = true
      }
      //println("report_cont_read usb_read_cont: \(usb_read_cont)")
   }
   
   
   
    
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
