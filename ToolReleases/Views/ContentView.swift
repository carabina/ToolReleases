//
//  ContentView.swift
//  ToolReleases
//
//  Created by Maris Lagzdins on 06/03/2020.
//  Copyright © 2020 Maris Lagzdins. All rights reserved.
//

import Combine
import os.log
import SwiftUI
import ToolReleasesCore

struct ContentView: View {
    @EnvironmentObject private var toolManager: ToolManager
    @State private var filter = ToolFilter.all
    @State private var relativeDateTimeTimer = Timer.makeRelativeDateTimeTimer().autoconnect()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter
    }()

    private var sortedTools: [Tool] {
        toolManager.tools
            .filtered(by: filter)
            .sorted(by: { $0.date > $1.date })
    }

    private var formattedLastRefreshDate: String {
        if let date = toolManager.lastRefresh {
            return "Last refresh: \(Self.formatter.string(from: date))"
        }

        return "Data hasn't loaded yet"
    }

    var body: some View {
        VStack {
            // Filter section
            HStack {
                Picker("Select filter", selection: $filter) {
                    ForEach(ToolFilter.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()

                PreferencesView()
            }
            .padding([.top, .horizontal])

            Divider()

            // List section
            if toolManager.tools.isEmpty {
                // No tools are available
                Text("No information about the released tools")
                    .frame(maxHeight: .infinity)
                    .padding()
            } else if sortedTools.isEmpty {
                // No tools with specific filter are available
                Text("No releases available")
                    .frame(maxHeight: .infinity)
                    .padding()
            } else {
                GeometryReader { geometry in
                    List(self.sortedTools) { tool in
                        ToolRow(tool: tool, timer: self.relativeDateTimeTimer)
                            .frame(width: geometry.size.width - 36, alignment: .leading)
                            .onTapGesture {
                                self.open(tool)
                        }
                    }
                    .listStyle(SidebarListStyle())
                }
            }

            Divider()

            HStack {
                Text(formattedLastRefreshDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: self.fetch) {
                    if toolManager.isRefreshing {
                        ActivityIndicatorView(spinning: true)
                    } else {
                        Image("refresh")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(toolManager.isRefreshing)
            }
            .padding(.bottom, 10)
            .padding(.horizontal)
        }
        .onAppear {
            self.fetch()
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverWillAppear)) { _ in
            os_log(.debug, log: .views, "Popover will appear event received")
            self.startTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidDisappear)) { _ in
            os_log(.debug, log: .views, "Popover did disappear event received")
            self.stopTimer()
        }
    }

    private func open(_ tool: Tool) {
        if let url = tool.url {
            NSWorkspace.shared.open(url)
        }
    }

    private func fetch() {
        toolManager.fetch()
    }

    private func startTimer() {
        stopTimer()
        self.relativeDateTimeTimer = Timer.makeRelativeDateTimeTimer().autoconnect()
    }

    private func stopTimer() {
        self.relativeDateTimeTimer.upstream.connect().cancel()
    }
}

fileprivate extension Timer {
    static func makeRelativeDateTimeTimer() -> Timer.TimerPublisher {
        Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
