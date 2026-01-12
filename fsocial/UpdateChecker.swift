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
            
            // Current vs New version
            HStack {
                VStack(spacing: 2) {
                    Text(updateChecker.currentVersionString)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appTextMuted)
                    Text("Current")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextMuted.opacity(0.7))
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appAccent)
                
                VStack(spacing: 2) {
                    Text(updateChecker.latestVersion)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                    Text("New")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appAccent.opacity(0.7))
                }
            }
            .padding(.vertical, 8)
            
            // Release notes
            if !updateChecker.releaseNotes.isEmpty {
                ScrollView {
                    Text(updateChecker.releaseNotes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 120)
                .padding(8)
                .background(Color.appSecondary)
                .cornerRadius(6)
            }
            
            // Download progress
            if updateChecker.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: updateChecker.downloadProgress)
                        .progressViewStyle(.linear)
                    
                    HStack {
                        Text("Downloading...")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appTextMuted)
                        Spacer()
                        Text("\(Int(updateChecker.downloadProgress * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button("Later") {
                    updateChecker.cancelDownload()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.appSecondary)
                .cornerRadius(6)
                
                if updateChecker.isDownloading {
                    Button("Cancel") {
                        updateChecker.cancelDownload()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.2))
                    .foregroundStyle(Color.red)
                    .cornerRadius(6)
                } else {
                    Button("Download & Install") {
                        updateChecker.downloadAndInstall()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.appAccent)
                    .foregroundStyle(Color.white)
                    .cornerRadius(6)
                }
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
