import AppKit

private enum CompanionAction: Int, CaseIterable {
    case happy, nextCharacter, openChatGPT, openSelectedApp, screenshot

    var label: String {
        switch self {
        case .happy: return "Vui vẻ"
        case .nextCharacter: return "Nhân vật kế tiếp"
        case .openChatGPT: return "Mở ChatGPT"
        case .openSelectedApp: return "Mở ứng dụng đã chọn"
        case .screenshot: return "Chụp màn hình"
        }
    }
}

@main
final class PixiePopApp: NSObject, NSApplicationDelegate {
    private let defaults = UserDefaults.standard
    private var panel: NSPanel?
    private var sprite: SpriteView?
    private var settingsWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var toggleItem: NSMenuItem?
    private var toggleButton: NSButton?
    private var characterPicker: NSPopUpButton?
    private var doublePicker: NSPopUpButton?
    private var triplePicker: NSPopUpButton?
    private var selectedAppLabel: NSTextField?
    private var snapBox: NSButton?

    static func main() {
        let app = NSApplication.shared
        let delegate = PixiePopApp()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        defaults.register(defaults: [
            "character": 0, "doubleAction": 0, "tripleAction": 1,
            "size": 180.0, "opacity": 1.0, "animationSpeed": 1.0,
            "snapToEdge": true, "overlayEnabled": true
        ])
        makeStatusItem()
        makePanel()
        makeSettingsWindow()
        if defaults.bool(forKey: "overlayEnabled") { showPanel() }
        showSettings()
        UpdateChecker.check(manual: false)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func makeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "✦ PixiePop"
        let menu = NSMenu()
        let settings = NSMenuItem(title: "Cài đặt PixiePop", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        let toggle = NSMenuItem(title: "Dừng nhân vật nổi", action: #selector(toggleOverlay), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        toggleItem = toggle
        let update = NSMenuItem(title: "Kiểm tra cập nhật", action: #selector(checkUpdates), keyEquivalent: "")
        update.target = self
        menu.addItem(update)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Thoát PixiePop", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem?.menu = menu
    }

    private func makePanel() {
        let size = CGFloat(defaults.double(forKey: "size"))
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultX = visible.maxX - size - 24
        let defaultY = visible.minY + 70
        let storedX = defaults.object(forKey: "panelX") as? Double
        let storedY = defaults.object(forKey: "panelY") as? Double
        let x = min(max(CGFloat(storedX ?? Double(defaultX)), visible.minX), visible.maxX - size)
        let y = min(max(CGFloat(storedY ?? Double(defaultY)), visible.minY), visible.maxY - size)
        let window = NSPanel(contentRect: NSRect(x: x, y: y, width: size, height: size),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        let view = SpriteView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.autoresizingMask = [.width, .height]
        view.character = SpriteCharacter(rawValue: defaults.integer(forKey: "character")) ?? .pixiePop
        view.animationSpeed = defaults.double(forKey: "animationSpeed")
        view.onTap = { [weak self] count in self?.handleTap(count) }
        view.onLongPress = { [weak self] in self?.showSettings() }
        view.onPositionChanged = { [weak self] origin in self?.savePosition(origin) }
        window.contentView = view
        window.alphaValue = defaults.double(forKey: "opacity")
        sprite = view
        panel = window
    }

    private func makeSettingsWindow() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 590, height: 620),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered, defer: false)
        window.title = "PixiePop · Cài đặt"
        window.center()
        let content = NSView()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22)
        ])

        let title = NSTextField(labelWithString: "PixiePop")
        title.font = .boldSystemFont(ofSize: 25)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(NSTextField(labelWithString: "Bạn đồng hành nổi trên MacBook · kéo nhân vật để di chuyển"))

        let character = NSPopUpButton()
        character.addItems(withTitles: SpriteCharacter.allCases.map(\.label))
        character.selectItem(at: defaults.integer(forKey: "character"))
        character.target = self
        character.action = #selector(characterChanged(_:))
        characterPicker = character
        stack.addArrangedSubview(row("Nhân vật", character))

        let double = actionPicker(defaults.integer(forKey: "doubleAction"), #selector(doubleChanged(_:)))
        doublePicker = double
        stack.addArrangedSubview(row("Chạm 2 lần", double))
        let triple = actionPicker(defaults.integer(forKey: "tripleAction"), #selector(tripleChanged(_:)))
        triplePicker = triple
        stack.addArrangedSubview(row("Chạm 3 lần", triple))

        let appButton = NSButton(title: "Chọn ứng dụng…", target: self, action: #selector(selectApp))
        stack.addArrangedSubview(row("Mở ứng dụng", appButton))
        let appLabel = NSTextField(labelWithString: selectedAppName())
        appLabel.textColor = .secondaryLabelColor
        selectedAppLabel = appLabel
        stack.addArrangedSubview(appLabel)

        stack.addArrangedSubview(row("Kích thước", slider(min: 90, max: 300,
            value: defaults.double(forKey: "size"), action: #selector(sizeChanged(_:)))))
        stack.addArrangedSubview(row("Độ mờ", slider(min: 0.4, max: 1,
            value: defaults.double(forKey: "opacity"), action: #selector(opacityChanged(_:)))))
        stack.addArrangedSubview(row("Tốc độ hoạt ảnh", slider(min: 0.5, max: 2,
            value: defaults.double(forKey: "animationSpeed"), action: #selector(speedChanged(_:)))))

        let snap = NSButton(checkboxWithTitle: "Bám cạnh màn hình khi thả", target: self,
                            action: #selector(snapChanged(_:)))
        snap.state = defaults.bool(forKey: "snapToEdge") ? .on : .off
        snapBox = snap
        stack.addArrangedSubview(snap)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let toggle = NSButton(title: "Dừng nhân vật nổi", target: self, action: #selector(toggleOverlay))
        toggleButton = toggle
        buttons.addArrangedSubview(toggle)
        buttons.addArrangedSubview(NSButton(title: "Kiểm tra cập nhật", target: self,
                                            action: #selector(checkUpdates)))
        stack.addArrangedSubview(buttons)

        let hint = NSTextField(wrappingLabelWithString:
            "Chạm 1 lần: mở ChatGPT. Nhấn giữ: mở cài đặt. Chụp màn hình có thể cần cấp quyền Ghi màn hình trong Cài đặt macOS. Bản cập nhật tải từ GitHub Releases; kéo ứng dụng mới vào Applications để cài đè.")
        hint.textColor = .secondaryLabelColor
        hint.maximumNumberOfLines = 3
        hint.preferredMaxLayoutWidth = 535
        stack.addArrangedSubview(hint)
        window.contentView = content
        settingsWindow = window
    }

    private func row(_ label: String, _ control: NSView) -> NSStackView {
        let title = NSTextField(labelWithString: label)
        title.widthAnchor.constraint(equalToConstant: 158).isActive = true
        control.widthAnchor.constraint(equalToConstant: 280).isActive = true
        let row = NSStackView(views: [title, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        return row
    }

    private func slider(min: Double, max: Double, value: Double, action: Selector) -> NSSlider {
        let slider = NSSlider(value: value, minValue: min, maxValue: max,
                              target: self, action: action)
        slider.isContinuous = true
        return slider
    }

    private func actionPicker(_ index: Int, _ action: Selector) -> NSPopUpButton {
        let picker = NSPopUpButton()
        picker.addItems(withTitles: CompanionAction.allCases.map(\.label))
        picker.selectItem(at: index)
        picker.target = self
        picker.action = action
        return picker
    }

    @objc private func showSettings() {
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleOverlay() {
        if panel?.isVisible == true {
            panel?.orderOut(nil)
            defaults.set(false, forKey: "overlayEnabled")
        } else {
            showPanel()
            defaults.set(true, forKey: "overlayEnabled")
        }
        let label = panel?.isVisible == true ? "Dừng nhân vật nổi" : "Bắt đầu nhân vật nổi"
        toggleItem?.title = label
        toggleButton?.title = label
    }

    private func showPanel() {
        panel?.orderFrontRegardless()
        toggleItem?.title = "Dừng nhân vật nổi"
        toggleButton?.title = "Dừng nhân vật nổi"
    }

    @objc private func checkUpdates() { UpdateChecker.check(manual: true) }
    @objc private func quitApp() { NSApp.terminate(nil) }

    @objc private func characterChanged(_ sender: NSPopUpButton) {
        let value = sender.indexOfSelectedItem
        defaults.set(value, forKey: "character")
        sprite?.character = SpriteCharacter(rawValue: value) ?? .pixiePop
    }

    @objc private func doubleChanged(_ sender: NSPopUpButton) {
        defaults.set(sender.indexOfSelectedItem, forKey: "doubleAction")
    }

    @objc private func tripleChanged(_ sender: NSPopUpButton) {
        defaults.set(sender.indexOfSelectedItem, forKey: "tripleAction")
    }

    @objc private func sizeChanged(_ sender: NSSlider) {
        defaults.set(sender.doubleValue, forKey: "size")
        panel?.setContentSize(NSSize(width: sender.doubleValue, height: sender.doubleValue))
        if let origin = panel?.frame.origin { savePosition(origin) }
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        defaults.set(sender.doubleValue, forKey: "opacity")
        panel?.alphaValue = sender.doubleValue
    }

    @objc private func speedChanged(_ sender: NSSlider) {
        defaults.set(sender.doubleValue, forKey: "animationSpeed")
        sprite?.animationSpeed = sender.doubleValue
    }

    @objc private func snapChanged(_ sender: NSButton) {
        defaults.set(sender.state == .on, forKey: "snapToEdge")
    }

    @objc private func selectApp() {
        let chooser = NSOpenPanel()
        chooser.title = "Chọn ứng dụng để mở bằng PixiePop"
        chooser.directoryURL = URL(fileURLWithPath: "/Applications")
        chooser.canChooseDirectories = false
        chooser.canChooseFiles = true
        chooser.allowsMultipleSelection = false
        chooser.allowedFileTypes = ["app"]
        if chooser.runModal() == .OK, let url = chooser.url {
            defaults.set(url.path, forKey: "selectedAppPath")
            selectedAppLabel?.stringValue = selectedAppName()
        }
    }

    private func selectedAppName() -> String {
        guard let path = defaults.string(forKey: "selectedAppPath") else {
            return "Chưa chọn ứng dụng"
        }
        return URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    private func savePosition(_ origin: NSPoint) {
        guard let panel else { return }
        var adjusted = origin
        if defaults.bool(forKey: "snapToEdge"),
           let area = panel.screen?.visibleFrame {
            let left = abs(origin.x - area.minX)
            let right = abs(area.maxX - panel.frame.width - origin.x)
            adjusted.x = left <= right ? area.minX : area.maxX - panel.frame.width
            panel.setFrameOrigin(adjusted)
        }
        defaults.set(Double(adjusted.x), forKey: "panelX")
        defaults.set(Double(adjusted.y), forKey: "panelY")
    }

    private func handleTap(_ count: Int) {
        guard let sprite else { return }
        if count == 1 {
            sprite.show(.happy, for: 1)
            openChatGPT()
            return
        }
        let key = count == 2 ? "doubleAction" : "tripleAction"
        let action = CompanionAction(rawValue: defaults.integer(forKey: key)) ?? .happy
        switch action {
        case .happy: sprite.show(.happy, for: 2)
        case .nextCharacter:
            let next = (sprite.character.rawValue + 1) % SpriteCharacter.allCases.count
            sprite.character = SpriteCharacter(rawValue: next) ?? .pixiePop
            characterPicker?.selectItem(at: next)
            defaults.set(next, forKey: "character")
            sprite.show(.reacting, for: 1)
        case .openChatGPT: openChatGPT()
        case .openSelectedApp: openSelectedApp()
        case .screenshot: takeScreenshot()
        }
    }

    private func openChatGPT() {
        for identifier in ["com.openai.chat", "com.openai.chatgpt"] {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
                NSWorkspace.shared.openApplication(at: url, configuration: .init(),
                                                   completionHandler: nil)
                return
            }
        }
        NSWorkspace.shared.open(URL(string: "https://chatgpt.com/")!)
    }

    private func openSelectedApp() {
        guard let path = defaults.string(forKey: "selectedAppPath"),
              FileManager.default.fileExists(atPath: path) else {
            showSettings()
            return
        }
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: .init(),
                                           completionHandler: nil)
    }

    private func takeScreenshot() {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Pictures/PixiePop", isDirectory: true)
        do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) }
        catch { showError("Không tạo được thư mục ảnh: \(error.localizedDescription)"); return }
        let stamp = DateFormatter()
        stamp.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let url = folder.appendingPathComponent("PixiePop_\(stamp.string(from: Date())).png")
        let displayIndex = NSScreen.screens.firstIndex(where: { $0 == panel?.screen }) ?? 0
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-x", "-D", String(displayIndex + 1), url.path]
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus != 0 {
                    DispatchQueue.main.async { self?.showError(
                        "Không chụp được màn hình. Kiểm tra quyền Ghi màn hình trong Cài đặt macOS.") }
                }
            } catch {
                DispatchQueue.main.async { self?.showError("Không chụp được màn hình: \(error.localizedDescription)") }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "PixiePop"
        alert.informativeText = message
        alert.runModal()
    }
}
