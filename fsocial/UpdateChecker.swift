import Foundation
import SwiftUI
import Combine
import AppKit

class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion: String = ""
    @Published var downloadURL: URL?
    @Published var releaseNotes: String = ""
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadedDMGPath: URL?
    
    private let currentVersion: String
    private let githubRepo = "buildmase/fsocial"
    private var downloadTask: URLSessionDownloadTask?
    
    var currentVersionString: String { currentVersion }
    
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
    
    // MARK: - Auto Download & Install
    
    func downloadAndInstall() {
        guard let url = downloadURL else {
            openDownloadPage()
            return
        }
        
        isDownloading = true
        downloadProgress = 0
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(checker: self), delegateQueue: nil)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0
    }
    
    func openDownloadedDMG() {
        guard let dmgPath = downloadedDMGPath else { return }
        NSWorkspace.shared.open(dmgPath)
    }
    
    func installUpdate() {
        guard let dmgPath = downloadedDMGPath else { return }
        
        // Open the DMG
        NSWorkspace.shared.open(dmgPath)
        
        // Show instructions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let alert = NSAlert()
            alert.messageText = "Installing Update"
            alert.informativeText = "Drag Social Hub to the Applications folder to complete the update, then relaunch the app."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - Download Delegate
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var checker: UpdateChecker?
    
    init(checker: UpdateChecker) {
        self.checker = checker
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move to Downloads folder
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsURL.appendingPathComponent("fsocial-Update.dmg")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                self.checker?.downloadedDMGPath = destinationURL
                self.checker?.isDownloading = false
                self.checker?.downloadProgress = 1.0
                
                // Auto-open the DMG
                self.checker?.installUpdate()
            }
        } catch {
            print("Failed to move DMG: \(error)")
            DispatchQueue.main.async {
                self.checker?.isDownloading = false
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.checker?.downloadProgress = progress
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed: \(error)")
            DispatchQueue.main.async {
                self.checker?.isDownloading = false
            }
        }
    }
}

// MARK: - Update Alert View
struct UpdateAlertView: View {
    @ObservedObject var updateChecker: UpdateChecker
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient accent
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
                
                VStack(spacing: 4) {
                    Text("Update Available")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appText)
                    
                    Text("A new version of fsocial is ready")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appTextMuted)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            // Version comparison
            HStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(updateChecker.currentVersionString)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appTextMuted)
                    Text("Installed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.appTextMuted.opacity(0.6))
                        .textCase(.uppercase)
                }
                .frame(width: 100)
                
                ZStack {
                    Circle()
                        .fill(Color.appSecondary)
                        .frame(width: 32, height: 32)
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.appAccent)
                }
                
                VStack(spacing: 6) {
                    Text(updateChecker.latestVersion)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                    Text("Available")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.appAccent.opacity(0.7))
                        .textCase(.uppercase)
                }
                .frame(width: 100)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.appSecondary.opacity(0.5))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            // Release notes
            if !updateChecker.releaseNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's New")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appTextMuted)
                        .textCase(.uppercase)
                    
                    ScrollView {
                        Text(updateChecker.releaseNotes)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 80)
                }
                .padding(16)
                .background(Color.appSecondary.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            
            // Download progress
            if updateChecker.isDownloading {
                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appSecondary)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appAccent.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * updateChecker.downloadProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text("Downloading update...")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextMuted)
                        Spacer()
                        Text("\(Int(updateChecker.downloadProgress * 100))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button {
                    updateChecker.cancelDownload()
                    isPresented = false
                } label: {
                    Text("Later")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSecondary)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                if updateChecker.isDownloading {
                    Button {
                        updateChecker.cancelDownload()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        updateChecker.downloadAndInstall()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                            Text("Update Now")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appAccent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(width: 380)
        .background(Color.appBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Update Banner (for persistent notification)
struct UpdateBanner: View {
    @ObservedObject var updateChecker: UpdateChecker
    var onDismiss: () -> Void
    var onUpdate: () -> Void
    
    var body: some View {
        if updateChecker.updateAvailable && !updateChecker.isDownloading {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appAccent)
                
                Text("Update available: v\(updateChecker.latestVersion)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appText)
                
                Spacer()
                
                Button("Update Now") {
                    onUpdate()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.appAccent)
                .cornerRadius(4)
                .buttonStyle(.plain)
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.appTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.appSecondary)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.appBorder),
                alignment: .bottom
            )
        }
    }
}
