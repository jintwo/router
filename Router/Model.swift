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
    
    static func loadBundledConfig(_ logger: Logger) -> Config {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return Self.empty()
        }
        
        do {
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            logger.error("error: \(error)")
            return Config.empty()
        }
    }
    
    static func loadUserConfig(_ logger: Logger) -> Config {
        let dir = try? FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false);
        logger.info("trying to find config at path: \(dir!)")
        let url = dir?.appendingPathComponent("router").appendingPathExtension("json")
        
        guard let data = try? Data(contentsOf: url!) else {
            logger.info("file at \(url!) not found")
            return Config.empty()
        }
        
        do {
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            logger.error("error: \(error)")
            return Config.empty()
        }
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
