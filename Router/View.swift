//
//  View.swift
//  Router
//
//  Created by Eugeny Volobuev on 27/11/24.
//
import SwiftUI

func getApps() -> [(String, String)] {
    var apps = [(String, String)]()
    let fileManager = FileManager.default
    
    for domain in [FileManager.SearchPathDomainMask.userDomainMask,
                   FileManager.SearchPathDomainMask.systemDomainMask,
                   FileManager.SearchPathDomainMask.localDomainMask] {
        if let appsURL = fileManager.urls(for: .applicationDirectory, in: domain).first {
            if let enumerator = fileManager.enumerator(at: appsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
                while let element = enumerator.nextObject() as? URL {
                    if element.pathExtension == "app" { // checks the extension
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

struct SettingsView: View {
    @Binding var config: Config
    @State var newPattern: String = ""
    @State var newPatternEditVisible: Bool = false
    @State var currentSectionID: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            GroupBox {
                Picker("Default handler", selection: $config.default_app) {
                    ForEach(getApps(), id: \.self.1) {
                        Text($0.0)
                    }
                }.bold()
            }
            ForEach($config.rules) { $rule in
                GroupBox {
                    HStack(alignment: .top) {
                        Picker("Handler", selection: $rule.app) {
                            ForEach(getApps(), id: \.self.1) {
                                Text($0.0)
                            }
                        }.bold()
                        VStack(alignment: .trailing) {
                            ForEach(rule.patterns) {
                                pattern in HStack(alignment: .center) {
                                    Text(pattern.value).italic()
                                    Spacer()
                                    Button("Del", systemImage: "clear") {
                                        rule.patterns = rule.patterns.filter({ $0.id != pattern.id })
                                    }
                                }
                            }
                            if newPatternEditVisible && currentSectionID == rule.id {
                                HStack {
                                    TextField("URL", text: $newPattern)
                                    Spacer()
                                    Button("Save", systemImage: "lock.square") {
                                        rule.patterns.append(Pattern(value: newPattern))
                                        newPattern = ""
                                        newPatternEditVisible = false
                                        currentSectionID = ""
                                    }
                                }
                            }
                            Button("Add", systemImage: "plus.app") {
                                newPatternEditVisible = true
                                currentSectionID = rule.id
                            }
                        }
                    }
                }
            }
            Button("Add", systemImage: "plus.app") {
                config.rules.append(Rule(app: config.default_app, patterns: []))
            }
        }.padding()
    }
}
