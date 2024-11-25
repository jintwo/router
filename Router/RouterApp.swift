//
//  RouterApp.swift
//  Router
//
//  Created by Eugeny Volobuev on 21/11/24.
//

import SwiftUI
import OSLog

class Delegate: NSObject, NSApplicationDelegate, ObservableObject {
    public var config: Config?
    public var logger: Logger?

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
                self.logger!.info("pattern: \(pattern)")
                let pat = try! Regex(pattern)
                let strURL = url.absoluteString
                if strURL.contains(pat) {
                    self.logger!.info("matched app: \(rule.app)")
                    return URL(string: rule.app)!
                }
            }
        }
        self.logger!.info("default app: \(self.config!.default_app)")
        return URL(string: self.config!.default_app)!
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
}

struct Config : Codable {
    let default_app: String
    let rules: [Rule]
}

struct Rule : Codable {
    let app: String
    let patterns: [String]
}

func loadBundledConfig(_ logger: Logger) -> Config? {
    guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        return nil
    }
    
    do {
        return try JSONDecoder().decode(Config.self, from: data)
    } catch {
        logger.error("error: \(error)")
        return nil
    }
}

func loadUserConfig(_ logger: Logger) -> Config? {
    let dir = try? FileManager.default.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: false);
    logger.info("trying to find config at path: \(dir!)")
    let url = dir?.appendingPathComponent("router").appendingPathExtension("json")
    
    guard let data = try? Data(contentsOf: url!) else {
        logger.info("file at \(url!) not found")
        return nil
    }
    
    do {
        return try JSONDecoder().decode(Config.self, from: data)
    } catch {
        logger.error("error: \(error)")
        return nil
    }
}

@available(macOS 13.0, *)
@main
struct RouterApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: Delegate
    private var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                        category: "logging")
    
    func reloadConfig(_ logger: Logger) {
        if let cfg = loadUserConfig(logger) {
            logger.info("using ~/router")
            appDelegate.config = cfg
        } else {
            logger.info("using bundled config")
            appDelegate.config = loadBundledConfig(logger)
        }
    }
    
    init() {
        reloadConfig(self.logger)
        appDelegate.logger = logger
    }
    
    var body: some Scene {
        MenuBarExtra("Router", systemImage: "arrow.branch") {
            Button("Reload") { reloadConfig(logger) }
                .keyboardShortcut("R")
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("Q")
        }
    }
}
