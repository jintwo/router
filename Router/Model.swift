//
//  Model.swift
//  Router
//
//  Created by Eugeny Volobuev on 27/11/24.
//
import OSLog

@Observable
class Config : Codable {
    var default_app: String
    var rules: [Rule]
    var isEmpty: Bool { default_app.isEmpty && rules.isEmpty }
        
    enum CodingKeys: String, CodingKey {
        case _default_app = "default_app"
        case _rules = "rules"
    }

    init(default_app: String, rules: [Rule]) {
        self.default_app = default_app
        self.rules = rules
    }

    static func empty() -> Config {
        return Config(default_app: "", rules: [])
    }
}

@Observable
class Rule : Codable, Identifiable {
    var app: String
    var patterns: [Pattern]
    var id: String { app }
    
    enum CodingKeys: String, CodingKey {
        case _app = "app"
        case _patterns = "patterns"
    }

    init(app: String, patterns: [Pattern]) {
        self.app = app
        self.patterns = patterns
    }
}

@Observable
class Pattern : Codable, Identifiable {
    var value: String
    var id: String { value }
    
    enum CodingKeys: String, CodingKey {
        case _value = "value"
    }

    init(value: String) {
        self.value = value
    }
}

class Model: ObservableObject {
    var config: Config = Config.empty()
    var configFileURL: URL?
    var logger: Logger?
    
    func loadBundledConfig() -> (Config, URL?) {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return (Config.empty(), .none)
        }
        
        do {
            return (try JSONDecoder().decode(Config.self, from: data), url)
        } catch {
            logger!.error("error: \(error)")
            return (Config.empty(), .none)
        }
    }
    
    func loadUserConfig() -> (Config, URL?) {
        let dir = try? FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false);
        logger!.debug("trying to find config at path: \(dir!)")
        let url = dir?.appendingPathComponent("router").appendingPathExtension("json")
        
        guard let data = try? Data(contentsOf: url!) else {
            logger!.debug("file at \(url!) not found")
            return (Config.empty(), .none)
        }
        
        do {
            return (try JSONDecoder().decode(Config.self, from: data), url!)
        } catch {
            logger!.error("error: \(error)")
            return (Config.empty(), .none)
        }
    }

    func reloadConfig() {
        var (cfg, url) = loadUserConfig()
        if cfg.isEmpty {
            (cfg, url) = loadBundledConfig()
        }
        self.config = cfg
        self.configFileURL = url
    }
    
    func dumpConfig() {
        let data = try! JSONEncoder().encode(config)
        let val = String(data: data, encoding: .utf8)
        logger!.debug("data: \(val!)")
        FileManager.default.createFile(atPath: self.configFileURL!.path(),
                                       contents: data)
    }
        
    func matchURL(_ url: URL) -> URL {
        for rule in config.rules {
            for pattern in rule.patterns {
                logger!.debug("pattern: \(pattern.value)")
                let pat = try! Regex(pattern.value)
                let strURL = url.absoluteString
                if strURL.contains(pat) {
                    logger!.debug("matched app: \(rule.app)")
                    return URL(string: rule.app)!
                }
            }
        }
        logger!.debug("default app: \(self.config.default_app)")
        return URL(string: self.config.default_app)!
    }
    
    static func getApps() -> [(String, String)] {
        var apps = [(String, String)]()
        let fileManager = FileManager.default
        
        for domain in [FileManager.SearchPathDomainMask.userDomainMask,
                       FileManager.SearchPathDomainMask.systemDomainMask,
                       FileManager.SearchPathDomainMask.localDomainMask] {
            if let appsURL = fileManager.urls(for: .applicationDirectory, in: domain).first {
                if let enumerator = fileManager.enumerator(at: appsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
                    while let element = enumerator.nextObject() as? URL {
                        if element.pathExtension == "app" && !element.pathComponents.last!.hasPrefix(".") {
                            let name = element.deletingPathExtension().lastPathComponent
                            var path = element.standardizedFileURL.absoluteString
                            path.removeLast()
                            apps.append((name, path))
                        }
                    }
                }
            }
        }
        apps.sort { $0.0 < $1.0 }
        
        return apps
    }
}

