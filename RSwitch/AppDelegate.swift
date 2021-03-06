//
// The main app delegate b/c AppKit isn't smart enough to deal with status bar apps yet
//

// ~/Library/Preferences/is.rud.rswitch.plist

import Cocoa
import SwiftUI
import ProcLib
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  var popover = NSPopover.init()
  var statusBar: StatusBarController?
  var timer: Timer? = nil;
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error { debugPrint("\(error)") }
      DispatchQueue.main.async { Preferences.notificationsAllowed = granted }
    }
    
    let contentView = ContentView()
    
    popover.contentViewController = MainViewController()
    popover.contentSize = NSSize(width: 300, height: 300)
    popover.contentViewController?.view = NSHostingView(rootView: contentView)
    
    statusBar = StatusBarController.init(popover)
    
    URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
    
    timer = Timer.scheduledTimer(
      timeInterval: 3600,
      target: self,
      selector: #selector(performTimer),
      userInfo: nil,
      repeats: true
    )
    
    performTimer(nil)
    
  }
  
  func applicationWillFinishLaunching(_ aNotification: Notification) {
    if Preferences.firstRunGone == false { Preferences.firstRunGone = true }
    DockIcon.standard.setVisibility(Preferences.showDockIcon)
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    timer?.invalidate()
  }
  
}

extension AppDelegate {
  
  static var downloadObservers : [ String: NSKeyValueObservation? ]  = [
    "R-devel": nil,
    "RStudio": nil,
    "RS Pro": nil
  ]
  
  static let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
  
  static let targetSize = NSSize(width: 20.0, height: 20.0)
  static let rlogo = #imageLiteral(resourceName: "RLogo").resized(to: targetSize)
  
  @objc func performRStudioCheck(_ sender: NSObject?) {
    
    if (currentReachabilityStatus != .notReachable) {
      
      if (Preferences.hourlyRStudioCheck) {
        let v = RStudioUtils.latestVersionNumber()
        if (!Preferences.lastVersionNotified.isVersion(equalTo: v)) {
          if (v.last != "/") {
            DispatchQueue.main.async { Preferences.lastVersionNotified = v }
            notifyUser(title: "New Version Available", subtitle: "RStudio", body: "Version: \(v)")
          }
        }
      }
      
      if (Preferences.hourlyRStudioProCheck) {
        let vp = RStudioUtils.latestProVersionNumber()
        if (!Preferences.lastProVersionNotified.isVersion(equalTo: vp)) {
          if (vp.last != "/") {
            DispatchQueue.main.async { Preferences.lastProVersionNotified = vp }
            notifyUser(title: "New Version Available", subtitle: "RStudio Pro", body: "Version: \(vp)")
          }
        }
      }
      
    }
  }
  
  @objc func performTimer(_ sender: Timer?) {
    if (Preferences.hourlyRStudioCheck) { performRStudioCheck(sender) }
  }
  
}
