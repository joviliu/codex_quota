import SwiftUI
import Foundation
import ServiceManagement

@main
struct CodexLiteApp: App {
    @StateObject private var viewModel = QuotaViewModel()
    @AppStorage("showRemaining") private var showRemaining: Bool = false
    @AppStorage("selectedModelId") private var selectedModelId: String = "codex"

    var body: some Scene {
        MenuBarExtra {
            Menu("Select Model") {
                ForEach(viewModel.availableModels, id: \.id) { model in
                    Button {
                        selectedModelId = model.id
                    } label: {
                        if selectedModelId == model.id {
                            Text("✓ \(model.name)")
                        } else {
                            Text(model.name)
                        }
                    }
                }
            }
            
            Toggle("Show Remaining Quota", isOn: $showRemaining)
            
            Toggle("Launch at Login", isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { _ in viewModel.toggleLaunchAtLogin() }
            ))

            Divider()
            
            Button("Refresh") {
                Task {
                    await viewModel.fetch()
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text(viewModel.statusText(for: selectedModelId, showRemaining: showRemaining))
            }
        }
    }
}

struct LimitModel: Equatable {
    let id: String
    let name: String
}

class QuotaViewModel: ObservableObject {
    @Published var availableModels: [LimitModel] = []
    @Published var allLimits: [String: (primary: Int?, secondary: Int?)] = [:]
    @Published var isLaunchAtLoginEnabled: Bool = SMAppService.mainApp.status == .enabled
    
    private var timer: Timer?

    init() {
        Task { await fetch() }
        // Update every 4 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 240, repeats: true) { [weak self] _ in
            Task { await self?.fetch() }
        }
    }
    
    func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                isLaunchAtLoginEnabled = false
            } else {
                try SMAppService.mainApp.register()
                isLaunchAtLoginEnabled = true
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }

    @MainActor
    func fetch() async {
        do {
            let result = try await QuotaService.fetchQuota()
            self.availableModels = result.models
            self.allLimits = result.limits
        } catch {
            print("Error fetching: \(error)")
        }
    }
    
    func statusText(for selectedModelId: String, showRemaining: Bool) -> String {
        if allLimits.isEmpty {
            return "Fetching..."
        }
        guard let limits = allLimits[selectedModelId] else {
            return "No Data"
        }
        
        func format(_ val: Int?) -> String {
            guard let val = val else { return "--%" }
            return showRemaining ? "\(max(0, 100 - val))%" : "\(val)%"
        }
        
        let p = format(limits.primary)
        let s = format(limits.secondary)
        return "5H: \(p) | 1W: \(s)"
    }
}

struct QuotaService {
    static func getCodexPath() -> URL? {
        let candidates = [
            ProcessInfo.processInfo.environment["CODEX_CLI_PATH"],
            "/Applications/Codex.app/Contents/Resources/codex",
            "\(NSHomeDirectory())/Applications/Codex.app/Contents/Resources/codex"
        ].compactMap { $0 }
        
        for candidate in candidates {
            if FileManager.default.fileExists(atPath: candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }
        return nil
    }

    static func fetchQuota() async throws -> (models: [LimitModel], limits: [String: (primary: Int?, secondary: Int?)]) {
        guard let path = getCodexPath() else {
            throw NSError(domain: "CodexPath", code: 1, userInfo: [NSLocalizedDescriptionKey: "Codex CLI not found"])
        }
        
        let process = Process()
        process.executableURL = path
        process.arguments = ["app-server", "--listen", "stdio://"]
        var env = ProcessInfo.processInfo.environment
        if env["CODEX_HOME"] == nil {
            env["CODEX_HOME"] = "\(NSHomeDirectory())/.codex"
        }
        process.environment = env
        
        let stdin = Pipe()
        let stdout = Pipe()
        
        process.standardInput = stdin
        process.standardOutput = stdout
        
        try process.run()
        
        let initRequest = "{\"id\":1,\"method\":\"initialize\",\"params\":{\"clientInfo\":{\"name\":\"codex-lite\",\"title\":\"Codex Lite\",\"version\":\"1.0.0\"},\"capabilities\":null}}\n"
        try stdin.fileHandleForWriting.write(contentsOf: initRequest.data(using: .utf8)!)
        
        let readRequest = "{\"id\":2,\"method\":\"account/rateLimits/read\"}\n"
        try stdin.fileHandleForWriting.write(contentsOf: readRequest.data(using: .utf8)!)
        
        var parsedModels: [LimitModel] = []
        var parsedLimits: [String: (primary: Int?, secondary: Int?)] = [:]
        
        for try await line in stdout.fileHandleForReading.bytes.lines {
            guard let data = line.data(using: .utf8) else { continue }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = json["id"] as? Int {
                if id == 2 {
                    if let result = json["result"] as? [String: Any] {
                        if let rateLimitsByLimitId = result["rateLimitsByLimitId"] as? [String: Any] {
                            for (limitId, limitData) in rateLimitsByLimitId {
                                guard let limitDict = limitData as? [String: Any] else { continue }
                                
                                let limitName = limitDict["limitName"] as? String ?? limitId
                                let isCodex = limitId.lowercased() == "codex"
                                let displayName = isCodex ? "Codex (Default)" : limitName
                                
                                parsedModels.append(LimitModel(id: limitId, name: displayName))
                                
                                var primaryUsed: Int? = nil
                                var secondaryUsed: Int? = nil
                                
                                if let primary = limitDict["primary"] as? [String: Any], let used = primary["usedPercent"] as? Double {
                                    primaryUsed = Int(used)
                                }
                                if let secondary = limitDict["secondary"] as? [String: Any], let used = secondary["usedPercent"] as? Double {
                                    secondaryUsed = Int(used)
                                }
                                
                                parsedLimits[limitId] = (primaryUsed, secondaryUsed)
                            }
                        } else if let limitDict = result["rateLimits"] as? [String: Any] {
                            let limitId = "codex"
                            parsedModels.append(LimitModel(id: limitId, name: "Codex (Default)"))
                            
                            var primaryUsed: Int? = nil
                            var secondaryUsed: Int? = nil
                            if let primary = limitDict["primary"] as? [String: Any], let used = primary["usedPercent"] as? Double {
                                primaryUsed = Int(used)
                            }
                            if let secondary = limitDict["secondary"] as? [String: Any], let used = secondary["usedPercent"] as? Double {
                                secondaryUsed = Int(used)
                            }
                            parsedLimits[limitId] = (primaryUsed, secondaryUsed)
                        }
                    }
                    break
                }
            }
        }
        process.terminate()
        
        parsedModels.sort { a, b in
            if a.id == "codex" { return true }
            if b.id == "codex" { return false }
            return a.name < b.name
        }
        
        return (parsedModels, parsedLimits)
    }
}
