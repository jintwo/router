//
//  RouterApp.swift
//  Router
//
//  Created by Eugeny Volobuev on 21/11/24.
//

import SwiftUI

class Delegate: NSObject, NSApplicationDelegate, ObservableObject {
    public var config: Config?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager
            .shared()
            .setEventHandler(self,
                             andSelector: #selector(handleURL(event:reply:)),
                             forEventClass: AEEventClass(kInternetEventClass),
                             andEventID: AEEventID(kAEGetURL))
    }
    
    func matchURL(url: URL) -> URL {
        for rule in config!.rules {
            for pattern in rule.patterns {
                NSLog("pattern: \(pattern)")
                let pat = try! Regex(pattern)
                let strURL = url.absoluteString
                if strURL.contains(pat) {
                    NSLog("matched app: \(rule.app)")
                    return URL(string: rule.app)!
                }
            }
        }
        NSLog("default app: \(config!.default_app)")
        return URL(string: config!.default_app)!
    }
    
    @objc func handleURL(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        if let path = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue?.removingPercentEncoding {
            let url = URL(string: path)!
            let appURL = matchURL(url: url)
            NSWorkspace.shared.open([url],
                                    withApplicationAt: appURL,
                                    configuration: NSWorkspace.OpenConfiguration())
        }
    }
}

struct Config : Codable {
    let default_app: String
    let rules: [Rule]
}

struct Rule : Codable {
    let app: String
    let patterns: [String]
}

func loadBundledConfig() -> Config? {
    guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        return nil
    }
    
    do {
        return try JSONDecoder().decode(Config.self, from: data)
    } catch {
        NSLog("error: \(error)")
        return nil
    }
}

func loadUserConfig() -> Config? {
    let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false);
    
    guard let url = dir?.appendingPathComponent("router").appendingPathExtension("json") ,
          let data = try? Data(contentsOf: url) else {
        return nil
    }
    
    do {
        return try JSONDecoder().decode(Config.self, from: data)
    } catch {
        NSLog("error: \(error)")
        return nil
    }
}

@available(macOS 13.0, *)
@main
struct RouterApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: Delegate
            
    func reloadConfig() {
        if let cfg = loadUserConfig() {
            NSLog("using ~/router")
            appDelegate.config = cfg
        } else {
            NSLog("using bundled config")
            appDelegate.config = loadBundledConfig()
        }
    }
    
    init() {
        reloadConfig()
    }
    
    var body: some Scene {
        MenuBarExtra("Router", systemImage: "arrow.branch") {
            Button("Reload") { reloadConfig() }
                .keyboardShortcut("R")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("Q")
        }
    }
}
