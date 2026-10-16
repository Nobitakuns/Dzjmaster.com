import AppKit

struct MacRelease: Decodable {
    struct Asset: Decodable {
        let name: String
        let browser_download_url: URL
    }

    let tag_name: String
    let assets: [Asset]
    let html_url: URL
}

enum UpdateChecker {
    static let currentVersion = "0.1.0"
    static let releasesURL = URL(string: "https://github.com/Nobitakuns/Dzjmaster.com/releases")!
    private static let apiURL = URL(string:
        "https://api.github.com/repos/Nobitakuns/Dzjmaster.com/releases?per_page=30")!

    static func isNewer(_ remote: String, than local: String) -> Bool {
        let left = remote.split(separator: ".").compactMap { Int($0) }
        let right = local.split(separator: ".").compactMap { Int($0) }
        guard left.count == 3 && right.count == 3 else { return false }
        for index in 0..<3 {
            if left[index] != right[index] { return left[index] > right[index] }
        }
        return false
    }

    static func check(manual: Bool) {
        var request = URLRequest(url: apiURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("PixiePop-macOS/0.1.0", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let release: MacRelease?
            if error == nil, let data,
               let status = (response as? HTTPURLResponse)?.statusCode,
               (200...299).contains(status),
               let all = try? JSONDecoder().decode([MacRelease].self, from: data) {
                release = all.filter { $0.tag_name.hasPrefix("pixiepop-mac-v") &&
                    $0.assets.contains(where: { $0.name.hasSuffix(".dmg") })
                }.max { a, b in
                    isNewer(String(b.tag_name.dropFirst("pixiepop-mac-v".count)),
                            than: String(a.tag_name.dropFirst("pixiepop-mac-v".count)))
                }
            } else {
                release = nil
            }
            DispatchQueue.main.async {
                guard let release else {
                    if manual { showUnavailable() }
                    return
                }
                let version = String(release.tag_name.dropFirst("pixiepop-mac-v".count))
                guard isNewer(version, than: currentVersion) else {
                    if manual { showMessage(title: "PixiePop đã cập nhật",
                                            message: "Bạn đang dùng bản macOS mới nhất (\(currentVersion)).") }
                    return
                }
                let alert = NSAlert()
                alert.messageText = "PixiePop \(version) đã có"
                alert.informativeText = "Tải DMG mới và kéo PixiePop vào Applications để thay bản cũ. Cài đặt nhân vật vẫn được giữ."
                alert.addButton(withTitle: "Tải bản mới")
                alert.addButton(withTitle: "Để sau")
                if alert.runModal() == .alertFirstButtonReturn,
                   let asset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }) {
                    download(asset)
                }
            }
        }.resume()
    }

    private static func download(_ asset: MacRelease.Asset) {
        URLSession.shared.downloadTask(with: asset.browser_download_url) { temporary, response, error in
            let destination = FileManager.default.urls(for: .downloadsDirectory,
                                                       in: .userDomainMask)[0]
                .appendingPathComponent(asset.name)
            var saved = false
            if error == nil, let temporary,
               let status = (response as? HTTPURLResponse)?.statusCode,
               (200...299).contains(status) {
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.moveItem(at: temporary, to: destination)
                    saved = true
                } catch { saved = false }
            }
            DispatchQueue.main.async {
                guard saved else {
                    let alert = NSAlert()
                    alert.messageText = "Không tải được bản cập nhật"
                    alert.informativeText = "Bạn có thể mở trang tải trong trình duyệt."
                    alert.addButton(withTitle: "Mở trang tải")
                    alert.addButton(withTitle: "Đóng")
                    if alert.runModal() == .alertFirstButtonReturn {
                        NSWorkspace.shared.open(asset.browser_download_url)
                    }
                    return
                }
                let alert = NSAlert()
                alert.messageText = "Đã tải PixiePop mới"
                alert.informativeText = "Mở DMG, kéo PixiePop vào Applications và chọn Thay thế để cập nhật."
                alert.addButton(withTitle: "Mở DMG")
                alert.addButton(withTitle: "Để sau")
                if alert.runModal() == .alertFirstButtonReturn { NSWorkspace.shared.open(destination) }
            }
        }.resume()
    }

    private static func showUnavailable() {
        let alert = NSAlert()
        alert.messageText = "Chưa kiểm tra được cập nhật"
        alert.informativeText = "Kiểm tra kết nối mạng hoặc mở trang phát hành PixiePop."
        alert.addButton(withTitle: "Mở trang phát hành")
        alert.addButton(withTitle: "Đóng")
        if alert.runModal() == .alertFirstButtonReturn { NSWorkspace.shared.open(releasesURL) }
    }

    private static func showMessage(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
