//
//  RouterApp.swift
//  Router
//
//  Created by Eugeny Volobuev on 21/11/24.
//

import SwiftUI
import OSLog

class Delegate: NSObject, NSApplicationDelegate, ObservableObject, NSWindowDelegate {
    public var config: Config = Config(default_app: "", rules: [])
    public var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                       category: "logging")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager
            .shared()
            .setEventHandler(self,
                             andSelector: #selector(handleURL(event:reply:)),
                             forEventClass: AEEventClass(kInternetEventClass),
                             andEventID: AEEventID(kAEGetURL))
        
        self.config = reloadConfig()
    }
    
    func matchURL(url: URL) -> URL {
        for rule in config.rules {
            for pattern in rule.patterns {
                self.logger.info("pattern: \(pattern.value)")
                let pat = try! Regex(pattern.value)
                let strURL = url.absoluteString
                if strURL.contains(pat) {
                    self.logger.info("matched app: \(rule.app)")
                    return URL(string: rule.app)!
                }
            }
        }
        self.logger.info("default app: \(self.config.default_app)")
        return URL(string: self.config.default_app)!
    }
    
    @objc func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        if let path = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue?.removingPercentEncoding {
            let url = URL(string: path)!
            let appURL = matchURL(url: url)
            let openConf = NSWorkspace.OpenConfiguration()
            openConf.activates = true
            NSWorkspace.shared.open([url],
                                    withApplicationAt: appURL,
                                    configuration: openConf)
        }
    }
    
    func reloadConfig() -> Config {
        var cfg = Config.loadUserConfig(self.logger)
        if cfg.isEmpty {
            cfg = Config.loadBundledConfig(self.logger)
            self.config = cfg
            self.logger.info("using bundled config")
        } else {
            self.config = cfg
            self.logger.info("using ~/router")
        }
        
        return cfg
    }
}

@main
struct RouterApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: Delegate
    @Environment(\.openWindow) var openWindow
    @State private var config: Config = Config(default_app: "", rules: [])

    func showConfigWindow() {
        config = appDelegate.reloadConfig()
        openWindow(id: "settings")
    }
    
    func dumpConfig(_ logger: Logger) {
        let data = try! JSONEncoder().encode(config)
        let val = String(data: data, encoding: .utf8)
        appDelegate.logger.info("data: \(val!)")
    }
    
    var body: some Scene {
            MenuBarExtra("Router", systemImage: "arrow.branch") {
                VStack {
                    Button("Config") { showConfigWindow() }
                        .keyboardShortcut("C")
                    Button("Reload") { self.config = appDelegate.reloadConfig() }
                        .keyboardShortcut("R")
                    Button("Dump") { dumpConfig(appDelegate.logger) }
                        .keyboardShortcut("D")
                    Divider()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .keyboardShortcut("Q")
                }
            }
            Window("Settings", id: "settings") {
                SettingsView(config: $config)
            }.windowResizability(.contentSize)
        }
    }
