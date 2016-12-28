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


class DataViewController: NSViewController, NSWindowDelegate, AVAudioPlayerDelegate
{
   @IBOutlet weak var inputDataFeld: NSTextView!

   
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
