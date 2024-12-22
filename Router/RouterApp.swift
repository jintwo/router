//
//  RouterApp.swift
//  Router
//
//  Created by Eugeny Volobuev on 21/11/24.
//

import SwiftUI
import OSLog

class Delegate: NSObject, NSApplicationDelegate, ObservableObject, NSWindowDelegate {
    public var model: Model = Model()
    public var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                       category: "logging")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager
            .shared()
            .setEventHandler(self,
                             andSelector: #selector(handleURL(event:reply:)),
                             forEventClass: AEEventClass(kInternetEventClass),
                             andEventID: AEEventID(kAEGetURL))
        
    }
    
    @objc func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        if let path = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue?.removingPercentEncoding {
            let url = URL(string: path)!
            let appURL = model.matchURL(url, self.logger)
            let openConf = NSWorkspace.OpenConfiguration()
            openConf.activates = true
            NSWorkspace.shared.open([url],
                                    withApplicationAt: appURL,
                                    configuration: openConf)
        }
    }
}

@main
struct RouterApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: Delegate
    @Environment(\.openWindow) var openWindow
    @State private var model: Model

    init() {
        self.model = Model()
        self.model.reloadConfig(appDelegate.logger)
        self.appDelegate.model = self.model
    }
    
    func showConfigWindow() {
        openWindow(id: "settings")
    }
    
    var body: some Scene {
            MenuBarExtra("Router", systemImage: "arrow.branch") {
                VStack {
                    Button("Config") { showConfigWindow() }
                        .keyboardShortcut("C")
                    Button("Reload") { model.reloadConfig(appDelegate.logger) }
                        .keyboardShortcut("R")
                    Button("Dump") { model.dumpConfig(appDelegate.logger) }
                        .keyboardShortcut("D")
                    Divider()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .keyboardShortcut("Q")
                }
            }
            Window("Settings", id: "settings") {
                SettingsView(config: $model.config)
            }.windowResizability(.contentSize)
        }
    }
