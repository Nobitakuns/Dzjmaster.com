import AppKit
import ImageIO

enum SpriteMood: Int, CaseIterable {
    case idle, happy, sad, sleeping, walking, talking, reacting

    var label: String {
        switch self {
        case .idle: return "Đứng yên"
        case .happy: return "Vui vẻ"
        case .sad: return "Buồn"
        case .sleeping: return "Ngủ"
        case .walking: return "Đi bộ"
        case .talking: return "Trò chuyện"
        case .reacting: return "Bất ngờ"
        }
    }
}

enum SpriteCharacter: Int, CaseIterable {
    case pixiePop, mimi, sunny, ruby, tabby, yuki, maiMai

    var label: String {
        switch self {
        case .pixiePop: return "PixiePop"
        case .mimi: return "Mimi mèo tím"
        case .sunny: return "Sunny radio"
        case .ruby: return "Ruby tim đỏ"
        case .tabby: return "Mèo Cam"
        case .yuki: return "Yuki mèo trắng"
        case .maiMai: return "Mai Mai hầu gái"
        }
    }

    var asset: String {
        switch self {
        case .pixiePop: return "ghostgirl_atlas"
        case .mimi: return "mimi_sheet"
        case .sunny: return "sunny_sheet"
        case .ruby: return "ruby_sheet"
        case .tabby: return "tabby_sheet"
        case .yuki: return "yuki_sheet"
        case .maiMai: return "maimai_sheet"
        }
    }

    func crop(for mood: SpriteMood, width: Int, height: Int) -> CGRect {
        if self == .pixiePop {
            let column = mood.rawValue % 4
            let row = mood.rawValue / 4
            return CGRect(x: column * width / 4, y: row * height / 2,
                          width: width / 4, height: height / 2)
        }
        let values: (CGFloat, CGFloat, CGFloat, CGFloat)
        switch mood {
        case .idle: values = (0.02, 0.02, 0.30, 0.54)
        case .happy: values = (0.45, 0.30, 0.59, 0.54)
        case .sad:
            if self == .ruby { values = (0.84, 0.30, 0.99, 0.54) }
            else if self == .tabby || self == .yuki || self == .maiMai {
                values = (0.59, 0.30, 0.74, 0.54)
            } else { values = (0.16, 0.55, 0.30, 0.77) }
        case .sleeping:
            values = self == .ruby ? (0.70, 0.55, 0.84, 0.77) : (0.84, 0.30, 0.99, 0.54)
        case .walking: values = (0.30, 0.30, 0.45, 0.54)
        case .talking: values = (0.02, 0.55, 0.16, 0.77)
        case .reacting: values = (0.30, 0.55, 0.43, 0.77)
        }
        return CGRect(x: Int(values.0 * CGFloat(width)), y: Int(values.1 * CGFloat(height)),
                      width: max(1, Int((values.2 - values.0) * CGFloat(width))),
                      height: max(1, Int((values.3 - values.1) * CGFloat(height))))
    }
}

final class SpriteView: NSView {
    var character: SpriteCharacter = .pixiePop { didSet { loadImage() } }
    var mood: SpriteMood = .idle { didSet { moodSince = Date(); needsDisplay = true } }
    var animationSpeed: Double = 1
    var onTap: ((Int) -> Void)?
    var onLongPress: (() -> Void)?
    var onPositionChanged: ((NSPoint) -> Void)?

    private var image: CGImage?
    private var moodSince = Date()
    private var moodUntil: Date?
    private var ticker: Timer?
    private var tapWork: DispatchWorkItem?
    private var longPressWork: DispatchWorkItem?
    private var mouseStart = NSPoint.zero
    private var windowStart = NSPoint.zero
    private var dragging = false
    private var longPressed = false

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadImage()
        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self, self.window?.isVisible == true else { return }
            if let until = self.moodUntil, Date() >= until {
                self.moodUntil = nil
                self.mood = .idle
            } else if self.mood == .idle && Date().timeIntervalSince(self.moodSince) > 60 {
                self.mood = .sleeping
            }
            self.needsDisplay = true
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    required init?(coder: NSCoder) { fatalError("Use init(frame:)") }
    deinit { ticker?.invalidate(); tapWork?.cancel(); longPressWork?.cancel() }

    func show(_ next: SpriteMood, for seconds: TimeInterval = 0) {
        mood = next
        moodUntil = seconds > 0 ? Date().addingTimeInterval(seconds) : nil
    }

    private func loadImage() {
        guard let url = Bundle.main.url(forResource: character.asset, withExtension: "png",
                                        subdirectory: "Sprites"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            image = nil
            return
        }
        self.image = image
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image,
              let cropped = image.cropping(to: character.crop(for: mood,
                                                               width: image.width,
                                                               height: image.height)),
              let context = NSGraphicsContext.current else { return }
        context.imageInterpolation = .none
        let aspect = CGFloat(cropped.width) / CGFloat(max(cropped.height, 1))
        let width = min(bounds.width, bounds.height * aspect)
        let height = min(bounds.height, bounds.width / aspect)
        let phase = Date().timeIntervalSinceReferenceDate * animationSpeed * .pi * 2
        let wave = sin(phase)
        let offset: CGFloat
        switch mood {
        case .happy: offset = CGFloat(abs(wave) * 5)
        case .walking: offset = CGFloat(abs(wave) * 2)
        case .sleeping: offset = 0
        default: offset = CGFloat(wave * 1.3)
        }
        let rect = NSRect(x: (bounds.width - width) / 2,
                          y: (bounds.height - height) / 2 + offset,
                          width: width, height: height)
        NSImage(cgImage: cropped, size: NSSize(width: CGFloat(cropped.width),
                                              height: CGFloat(cropped.height))).draw(in: rect)
    }

    override func mouseDown(with event: NSEvent) {
        tapWork?.cancel()
        mouseStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
        dragging = false
        longPressed = false
        longPressWork?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self, !self.dragging else { return }
            self.longPressed = true
            self.show(.reacting, for: 1)
            self.onLongPress?()
        }
        longPressWork = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: task)
    }

    override func mouseDragged(with event: NSEvent) {
        let current = NSEvent.mouseLocation
        let dx = current.x - mouseStart.x
        let dy = current.y - mouseStart.y
        guard dragging || hypot(dx, dy) > 4 else { return }
        dragging = true
        longPressWork?.cancel()
        tapWork?.cancel()
        show(.walking, for: 0.5)
        guard let window else { return }
        let screen = NSScreen.screens.first(where: { $0.frame.contains(current) })
            ?? window.screen ?? NSScreen.main
        let area = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let x = min(max(windowStart.x + dx, area.minX), area.maxX - window.frame.width)
        let y = min(max(windowStart.y + dy, area.minY), area.maxY - window.frame.height)
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    override func mouseUp(with event: NSEvent) {
        longPressWork?.cancel()
        if dragging {
            dragging = false
            if let origin = window?.frame.origin { onPositionChanged?(origin) }
            return
        }
        if longPressed { return }
        let count = min(event.clickCount, 3)
        tapWork?.cancel()
        if count == 3 {
            onTap?(3)
        } else {
            let task = DispatchWorkItem { [weak self] in self?.onTap?(count) }
            tapWork = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38, execute: task)
        }
    }
}
