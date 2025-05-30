//
//  View.swift
//  Router
//
//  Created by Eugeny Volobuev on 27/11/24.
//
import SwiftUI

struct SettingsView: View {
    @Binding var config: Config
    @State var newURLPattern: String = ""
    @State var newURLPatternEditVisible: Bool = false
    @State var newAppPattern: String = ""
    @State var newAppPatternEditVisible: Bool = false
    @State var currentSectionID: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            GroupBox {
                Picker("Default handler", selection: $config.default_app) {
                    ForEach(Model.getApps(), id: \.self.1) {
                        Text($0.0)
                    }
                }.bold()
            }
            ForEach($config.rules) { $rule in
                GroupBox {
                    HStack(alignment: .top) {
                        Picker("Handler", selection: $rule.app) {
                            ForEach(Model.getApps(), id: \.self.1) {
                                Text($0.0)
                            }
                        }.bold()
                        VStack(alignment: .trailing) {
                            Text("URL pattern").bold().italic()
                            ForEach(rule.urlPatterns) {
                                pattern in HStack(alignment: .center) {
                                    Text(pattern.value).italic()
                                    Spacer()
                                    Button("Del", systemImage: "clear") {
                                        rule.urlPatterns = rule.urlPatterns.filter({ $0.id != pattern.id })
                                    }
                                }
                            }
                            if newURLPatternEditVisible && currentSectionID == rule.id {
                                HStack {
                                    TextField("URL", text: $newURLPattern)
                                    Spacer()
                                    Button("Save", systemImage: "lock.square") {
                                        rule.urlPatterns.append(Pattern(value: newURLPattern))
                                        newURLPattern = ""
                                        newURLPatternEditVisible = false
                                        currentSectionID = ""
                                    }
                                }
                            }
                            Button("Add", systemImage: "plus.app") {
                                newURLPatternEditVisible = true
                                currentSectionID = rule.id
                            }
                        }
                        VStack(alignment: .trailing) {
                            Text("Source application").bold().italic()
                            ForEach(rule.appPatterns) {
                                pattern in HStack(alignment: .center) {
                                    Text(pattern.value).italic()
                                    Spacer()
                                    Button("Del", systemImage: "clear") {
                                        rule.appPatterns = rule.appPatterns.filter({ $0.id != pattern.id })
                                    }
                                }
                            }
                            if newAppPatternEditVisible && currentSectionID == rule.id {
                                HStack {
                                    TextField("App", text: $newAppPattern)
                                    Spacer()
                                    Button("Save", systemImage: "lock.square") {
                                        rule.appPatterns.append(Pattern(value: newAppPattern))
                                        newAppPattern = ""
                                        newAppPatternEditVisible = false
                                        currentSectionID = ""
                                    }
                                }
                            }
                            Button("Add", systemImage: "plus.app") {
                                newAppPatternEditVisible = true
                                currentSectionID = rule.id
                            }
                        }

                    }
                }
            }
            Button("Add", systemImage: "plus.app") {
                config.rules.append(Rule(app: config.default_app, urlPatterns: [], appPatterns: []))
            }
        }.padding()
    }
}
