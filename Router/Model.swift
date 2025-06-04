//
//  Model.swift
//  Router
//
//  Created by Eugeny Volobuev on 27/11/24.
//
import OSLog
import Observation

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
    var urlPatterns: [Pattern]
    var appPatterns: [Pattern]
    var id: String {
        app +
        urlPatterns.map { $0.id }.joined(separator: "+") +
        appPatterns.map { $0.id }.joined(separator: "+")
    }

    enum CodingKeys: String, CodingKey {
        case _app = "app"
        case _urlPatterns = "urlPatterns"
        case _appPatterns = "appPatterns"
    }

    init(app: String, urlPatterns: [Pattern], appPatterns: [Pattern]) {
        self.app = app
        self.urlPatterns = urlPatterns
        self.appPatterns = appPatterns
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

    func stringMatchesPattern(_ value: String, _ pattern: Pattern) -> Bool {
        logger!.debug("value: \(value) pattern: \(pattern.value)")
        let pat = try! Regex(pattern.value)
        return value.contains(pat)
    }

    func match(_ url: URL, _ app: String?) -> URL {
        for rule in config.rules {
            var hasAppMatch: Bool = false
            var hasURLMatch: Bool = false

            if rule.appPatterns.count > 0 {
                if let appName = app {
                    for pattern in rule.appPatterns {
                        if stringMatchesPattern(appName, pattern) {
                            logger!.debug("app has match: \(appName) \(pattern.value)")
                            hasAppMatch = true
                        }
                    }
                } else {
                    logger!.debug("unknown app")
                }
            } else {
                logger!.debug("no app rules")
                hasAppMatch = true
            }

            if !hasAppMatch {
                logger!.debug("no app match!")
                continue
            }

            if rule.urlPatterns.count > 0 {
                let strURL = url.absoluteString
                for pattern in rule.urlPatterns {
                    if stringMatchesPattern(strURL, pattern) {
                        logger!.debug("url has match: \(strURL) \(pattern.value)")
                        hasURLMatch = true
                    }
                }
            } else {
                hasURLMatch = true
            }

            if hasAppMatch && hasURLMatch {
                logger!.debug("HAS MATCH -> \(rule.app)")
                return URL(string: rule.app)!
            } else {
                logger!.debug("no url match!")
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
