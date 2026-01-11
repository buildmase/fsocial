import Foundation
import SwiftUI
import Combine

class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion: String = ""
    @Published var downloadURL: URL?
    @Published var releaseNotes: String = ""
    
    private let currentVersion: String
    private let githubRepo = "buildmase/fsocial"
    
    init() {
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let assets = json["assets"] as? [[String: Any]],
                   let body = json["body"] as? String {
                    
                    // Clean version string (remove 'v' prefix if present)
                    let latestVer = tagName.replacingOccurrences(of: "v", with: "")
                    
                    // Find DMG download URL
                    let dmgAsset = assets.first { asset in
                        (asset["name"] as? String)?.hasSuffix(".dmg") == true
                    }
                    let dmgURL = dmgAsset?["browser_download_url"] as? String
                    
                    DispatchQueue.main.async {
                        self.latestVersion = latestVer
                        self.releaseNotes = body
                        
                        if let urlString = dmgURL {
                            self.downloadURL = URL(string: urlString)
                        }
                        
                        // Compare versions
                        if self.isNewerVersion(latestVer, than: self.currentVersion) {
                            self.updateAvailable = true
                        }
                    }
                }
            } catch {
                print("Failed to parse release info: \(error)")
            }
        }.resume()
    }
    
    private func isNewerVersion(_ latest: String, than current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(latestParts.count, currentParts.count) {
            let latestPart = i < latestParts.count ? latestParts[i] : 0
            let currentPart = i < currentParts.count ? currentParts[i] : 0
            
            if latestPart > currentPart {
                return true
            } else if latestPart < currentPart {
                return false
            }
        }
        return false
    }
    
    func openDownloadPage() {
        if let url = downloadURL {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback to releases page
            if let url = URL(string: "https://github.com/\(githubRepo)/releases/latest") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - Update Alert View
struct UpdateAlertView: View {
    @ObservedObject var updateChecker: UpdateChecker
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.appAccent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available")
                        .font(.headline)
                        .foregroundStyle(Color.appText)
                    Text("Version \(updateChecker.latestVersion)")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextMuted)
                }
                
                Spacer()
            }
            
            // Release notes
            if !updateChecker.releaseNotes.isEmpty {
                ScrollView {
                    Text(updateChecker.releaseNotes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
                .padding(8)
                .background(Color.appSecondary)
                .cornerRadius(6)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button("Later") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.appSecondary)
                .cornerRadius(6)
                
                Button("Download Update") {
                    updateChecker.openDownloadPage()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.appAccent)
                .foregroundStyle(Color.white)
                .cornerRadius(6)
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(Color.appBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
