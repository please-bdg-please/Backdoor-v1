// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import AlertKit
import Foundation
import Nuke
import UIKit

extension SourceAppViewController: DownloadDelegate {
    func stopDownload(uuid: String) {
        DispatchQueue.main.async {
            if let task = DownloadTaskManager.shared.task(for: uuid) {
                if let cell = task.cell {
                    cell.stopDownload()
                }
                DownloadTaskManager.shared.removeTask(uuid: uuid)
            }
        }
    }

    func startDownload(uuid: String, indexPath _: IndexPath) {
        DispatchQueue.main.async {
            if let task = DownloadTaskManager.shared.task(for: uuid) {
                if let cell = task.cell {
                    cell.startDownload()
                }
                DownloadTaskManager.shared.updateTask(uuid: uuid, state: .inProgress(progress: 0.0))
            }
        }
    }

    func updateDownloadProgress(progress: Double, uuid: String) {
        DownloadTaskManager.shared.updateTask(uuid: uuid, state: .inProgress(progress: progress))
    }
}

extension SourceAppViewController {
    func startDownloadIfNeeded(for indexPath: IndexPath, in tableView: UITableView, downloadURL: URL?, appUUID: String?, sourceLocation: String) {
        guard let downloadURL = downloadURL, let appUUID = appUUID, let cell = tableView.cellForRow(at: indexPath) as? AppTableViewCell else {
            return
        }

        if cell.appDownload == nil {
            cell.appDownload = AppDownload()
            cell.appDownload?.dldelegate = self
        }
        
        // Show download animation in cell
        let animationView = cell.addLottieAnimation(
            name: "download_progress",
            loopMode: .loop,
            size: CGSize(width: 40, height: 40)
        )
        
        // Position animation in the cell
        animationView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // Add to task manager
        DownloadTaskManager.shared.addTask(uuid: appUUID, cell: cell, dl: cell.appDownload!)

        // Use NetworkManager to handle the download with improved error handling
        Task {
            do {
                // Create a temporary file path for the download
                let tempDir = FileManager.default.temporaryDirectory
                let filePath = tempDir.appendingPathComponent("app_\(appUUID).ipa")
                
                // Start download and show progress
                self.startDownload(uuid: appUUID, indexPath: indexPath)
                
                // Use the enhanced NetworkManager to download the file
                let downloadedURL = try await NetworkManager.shared.downloadFile(
                    .custom(url: downloadURL, method: .get, parameters: nil),
                    destinationURL: filePath
                )
                
                // Verify downloaded file integrity
                let fileData = try Data(contentsOf: downloadedURL)
                let checksum = CryptoHelper.shared.crc32(of: fileData)
                Debug.shared.log(message: "Download completed with checksum: \(checksum)", type: .info)
                
                // Extract and process the bundle
                cell.appDownload?.extractCompressedBundle(packageURL: downloadedURL) { [weak self] targetBundle, error in
                    guard let self = self else { return }
                    
                    // Remove animation when processing is complete
                    DispatchQueue.main.async {
                        animationView.removeFromSuperview()
                    }
                    
                    if let error = error {
                        DownloadTaskManager.shared.updateTask(uuid: appUUID, state: .failed(error: error))
                        Debug.shared.log(message: "Extraction error: \(error.localizedDescription)", type: .error)
                        
                        // Show error animation
                        let errorAnimation = cell.addLottieAnimation(
                            name: "error",
                            loopMode: .playOnce,
                            size: CGSize(width: 40, height: 40)
                        )
                        
                        errorAnimation.snp.makeConstraints { make in
                            make.trailing.equalToSuperview().offset(-16)
                            make.centerY.equalToSuperview()
                            make.width.height.equalTo(40)
                        }
                        
                        // Remove error animation after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            errorAnimation.removeFromSuperview()
                        }
                    } else if let targetBundle = targetBundle {
                        cell.appDownload?.addToApps(bundlePath: targetBundle, uuid: appUUID, sourceLocation: sourceLocation) { error in
                            if let error = error {
                                DownloadTaskManager.shared.updateTask(uuid: appUUID, state: .failed(error: error))
                                Debug.shared.log(message: "Failed to add app: \(error.localizedDescription)", type: .error)
                            } else {
                                DownloadTaskManager.shared.updateTask(uuid: appUUID, state: .completed)
                                Debug.shared.log(message: R.string.general.done, type: .success)
                                
                                // Show success animation
                                let successAnimation = cell.addLottieAnimation(
                                    name: "success",
                                    loopMode: .playOnce,
                                    size: CGSize(width: 40, height: 40)
                                )
                                
                                successAnimation.snp.makeConstraints { make in
                                    make.trailing.equalToSuperview().offset(-16)
                                    make.centerY.equalToSuperview()
                                    make.width.height.equalTo(40)
                                }
                                
                                // Remove success animation after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    successAnimation.removeFromSuperview()
                                }

                                // Check if immediate install is enabled
                                if UserDefaults.standard.signingOptions.immediatelyInstallFromSource {
                                    DispatchQueue.main.async {
                                        let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
                                        if let downloadedApp = downloadedApps.first(where: { $0.uuid == appUUID }) {
                                            NotificationCenter.default.post(
                                                name: Notification.Name("InstallDownloadedApp"),
                                                object: nil,
                                                userInfo: ["downloadedApp": downloadedApp]
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                // Handle download errors with enhanced error reporting
                DownloadTaskManager.shared.updateTask(uuid: appUUID, state: .failed(error: error))
                
                // Remove animation
                DispatchQueue.main.async {
                    animationView.removeFromSuperview()
                }
                
                // Log detailed error information
                if let networkError = error as? NetworkError {
                    Debug.shared.log(message: "Network download error: \(networkError.localizedDescription)", type: .error)
                    
                    // Add detailed error diagnostics
                    switch networkError {
                    case .httpError(let statusCode):
                        Debug.shared.log(message: "HTTP error status: \(statusCode)", type: .error)
                    case .invalidURL:
                        Debug.shared.log(message: "Invalid download URL: \(downloadURL)", type: .error)
                    default:
                        Debug.shared.log(message: "Download failed with error: \(error.localizedDescription)", type: .error)
                    }
                } else {
                    Debug.shared.log(message: "Download failed: \(error.localizedDescription)", type: .error)
                }
                
                // Show error animation
                let errorAnimation = cell.addLottieAnimation(
                    name: "error",
                    loopMode: .playOnce, 
                    size: CGSize(width: 40, height: 40)
                )
                
                errorAnimation.snp.makeConstraints { make in
                    make.trailing.equalToSuperview().offset(-16)
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(40)
                }
                
                // Remove error animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    errorAnimation.removeFromSuperview()
                }
            }
        }
    }
}

protocol DownloadDelegate: AnyObject {
    func updateDownloadProgress(progress: Double, uuid: String)
    func stopDownload(uuid: String)
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
}
