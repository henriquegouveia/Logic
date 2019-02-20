import AppKit

public typealias LogicTextID = String

public enum LogicEditorTextElement {
    case indent
    case unstyled(String)
    case colored(String, NSColor)
    case dropdown(LogicTextID, String, NSColor)

    var syntaxNodeID: String? {
        switch self {
        case .unstyled:
            return nil
        case .colored:
            return nil
        case .dropdown(let id, _, _):
            return id
        case .indent:
            return nil
        }
    }

    var value: String {
        switch self {
        case .unstyled(let value):
            return value
        case .colored(let value, _):
            return value
        case .dropdown(_, let value, _):
            return value
        case .indent:
            return ""
        }
    }

    var color: NSColor {
        switch self {
        case .unstyled:
            return NSColor.black
        case .colored(_, let color):
            return color
        case .dropdown(_, _, let color):
            return color
        case .indent:
            return NSColor.clear
        }
    }
}

private struct MeasuredEditorText {
    var text: LogicEditorTextElement
    var attributedString: NSAttributedString
    var attributedStringRect: CGRect
    var backgroundRect: CGRect
}

// MARK: - LogicEditor

public class LogicEditor: NSView {

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var lines: [[LogicEditorTextElement]] = [] { didSet { update() } }
    public var selectedIndexPath: IndexPath? { didSet { update() } }

    public var onActivateIndexPath: ((IndexPath?) -> Void)?

    public var textMargin = CGSize(width: 6, height: 6)
    public var textPadding = CGSize(width: 4, height: 3)
    public var textBackgroundRadius = CGSize(width: 2, height: 2)

    public var underlinedRange: NSRange?
    public var underlineColor: NSColor = NSColor.systemBlue
    public var underlineOffset: CGFloat = 2.0

    public var textSpacing: CGFloat = 4.0
    public var lineSpacing: CGFloat = 6.0
    public var minimumLineHeight: CGFloat = 20.0

    public var font = TextStyle(family: "San Francisco", size: 13).nsFont
//    public var font = TextStyle(family: "menlo", size: 13).nsFont

    // MARK: Overrides

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override var acceptsFirstResponder: Bool {
        return true
    }

    public func getBoundingRect(for indexPath: IndexPath) -> CGRect? {
        var rect: CGRect?

        measuredLines.enumerated().forEach { lineIndex, line in
            line.enumerated().forEach { textIndex, measuredText in
                if lineIndex == indexPath.section && textIndex == indexPath.item {
                    rect = flip(rect: measuredText.backgroundRect)
                }
            }
        }

        return rect
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        var indexPath: IndexPath? = nil

        measuredLines.enumerated().forEach { lineIndex, line in
            line.enumerated().forEach { textIndex, measuredText in
                if measuredText.backgroundRect.contains(point) {
                    indexPath = IndexPath(item: textIndex, section: lineIndex)
                }
            }
        }

        onActivateIndexPath?(indexPath)
    }

    public override func keyDown(with event: NSEvent) {
        Swift.print("LogicEditor kd", event.keyCode)

        switch Int(event.keyCode) {
        case 36: // Enter
            onActivateIndexPath?(selectedIndexPath)
        case 48: // Tab
            Swift.print("Tab")
        case 123: // Left
            Swift.print("Left arrow")
        case 124: // Right
            Swift.print("Right arrow")
        case 125: // Down
            Swift.print("Down arrow")
        case 126: // Up
            Swift.print("Up arrow")
        default:
            break
        }
    }

    public override var isFlipped: Bool {
        return true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSGraphicsContext.current?.cgContext.setShouldSmoothFonts(false)

        let measuredLines = self.measuredLines

        measuredLines.enumerated().forEach { lineIndex, line in
            line.enumerated().forEach { textIndex, measuredText in
                let selected = IndexPath(item: textIndex, section: lineIndex) == self.selectedIndexPath
                let text = measuredText.text
                let rect = measuredText.attributedStringRect
                let backgroundRect = measuredText.backgroundRect
                let attributedString = measuredText.attributedString

                switch (text) {
                case .indent:
                    break
                case .unstyled, .colored:
                    attributedString.draw(at: rect.origin)
                case .dropdown(_, let value, let color):
                    let color = selected ? NSColor.selectedMenuItemColor : color

                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 1
                    shadow.shadowOffset = NSSize(width: 0, height: -1)
                    shadow.shadowColor = NSColor.black.withAlphaComponent(0.2)
                    shadow.set()

                    if selected {
                        color.setFill()
                    } else {
                        NSColor.clear.setFill()
//                        NSColor.white.withAlphaComponent(0.2).setFill()
//                        color.highlight(withLevel: 0.7)?.setFill()
                    }

                    let backgroundPath = NSBezierPath(
                        roundedRect: backgroundRect,
                        xRadius: textBackgroundRadius.width,
                        yRadius: textBackgroundRadius.height)
                    backgroundPath.fill()

                    NSShadow().set()

                    if selected {
                        NSColor.white.setFill()
                    } else {
                        color.setFill()
                    }
                    let caretX = backgroundRect.maxX - (value.isEmpty ? 13 : 9)
                    let caretCenter = CGPoint(x: caretX, y: backgroundRect.midY)
                    let caretStart = CGPoint(x: caretX - 4, y: backgroundRect.midY)
                    let caret = NSBezierPath(regularPolygonAt: caretCenter, startPoint: caretStart, sides: 3)
                    caret.fill()

                    if selected {
                        let attributedString = NSMutableAttributedString(attributedString: attributedString)
                        attributedString.addAttributes(
                            [NSAttributedString.Key.foregroundColor: NSColor.white],
                            range: NSRange(location: 0, length: attributedString.length))
                        attributedString.draw(at: rect.origin)
                    } else {
                        attributedString.draw(at: rect.origin)
                    }
                }
            }
        }

//        if let range = underlinedRange, range.location + range.length < lines.count {
//            let first = measuredBody[range.location]
//            let last = measuredBody[range.location + range.length]
//
//            underlineColor.setFill()
//
//            let underlineRect = NSRect(
//                x: first.backgroundRect.minX,
//                y: first.backgroundRect.maxY + underlineOffset,
//                width: last.backgroundRect.maxX - first.backgroundRect.minX,
//                height: 2)
//
//            underlineRect.fill()
//        }
    }

    private var measuredLines: [[MeasuredEditorText]] {
        var measuredLines: [[MeasuredEditorText]] = []

        var yOffset = textMargin.height

        lines.enumerated().forEach { lineIndex, line in
            var xOffset = textMargin.width

            var measuredLine: [MeasuredEditorText] = []

            line.enumerated().forEach { textIndex, text in
                let selected = IndexPath(item: textIndex, section: lineIndex) == self.selectedIndexPath
                let attributedString = NSMutableAttributedString(string: text.value)
                let range = NSRange(location: 0, length: attributedString.length)

                switch (text) {
                case .indent:
                    let rect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: NSSize(width: 20, height: 0))

                    let measured = MeasuredEditorText(
                        text: text,
                        attributedString: NSAttributedString(string: ""),
                        attributedStringRect: rect,
                        backgroundRect: rect)

                    xOffset += rect.width + textSpacing

                    measuredLine.append(measured)
                case .unstyled:
                    let attributes: [NSAttributedString.Key: Any] = [
                        NSAttributedString.Key.foregroundColor: NSColor.black,
                        NSAttributedString.Key.font: font
                    ]
                    attributedString.setAttributes(attributes, range: range)

                    let attributedStringSize = attributedString.size()
                    let rect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: attributedStringSize)
                    let backgroundRect = rect.insetBy(dx: -textPadding.width, dy: -textPadding.height)

                    xOffset += backgroundRect.width + textSpacing

                    let measured = MeasuredEditorText(
                        text: text,
                        attributedString: attributedString,
                        attributedStringRect: rect,
                        backgroundRect: backgroundRect)

                    measuredLine.append(measured)
                case .colored(_, let color):
                    let color = selected ? NSColor.systemGreen : color

                    let attributes: [NSAttributedString.Key: Any] = [
                        NSAttributedString.Key.foregroundColor: color,
                        NSAttributedString.Key.font: font
                    ]
                    attributedString.setAttributes(attributes, range: range)

                    let attributedStringSize = attributedString.size()
                    let rect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: attributedStringSize)
                    let backgroundRect = rect.insetBy(dx: -textPadding.width, dy: -textPadding.height)

                    xOffset += backgroundRect.width + textSpacing

                    let measured = MeasuredEditorText(
                        text: text,
                        attributedString: attributedString,
                        attributedStringRect: rect,
                        backgroundRect: backgroundRect)

                    measuredLine.append(measured)
                case .dropdown(_, _, let color):
                    let color = selected ? NSColor.systemGreen : color
                    
                    let attributes: [NSAttributedString.Key: Any] = [
                        NSAttributedString.Key.foregroundColor: color,
                        NSAttributedString.Key.font: font
                    ]
                    attributedString.setAttributes(attributes, range: range)

                    let attributedStringSize = attributedString.size()
                    let rect = CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: attributedStringSize)
                    var backgroundRect = rect.insetBy(dx: -textPadding.width, dy: -textPadding.height)
                    backgroundRect.size.width += 14

                    xOffset += backgroundRect.width + textSpacing

                    let measured = MeasuredEditorText(
                        text: text,
                        attributedString: attributedString,
                        attributedStringRect: rect,
                        backgroundRect: backgroundRect)

                    measuredLine.append(measured)
                }
            }

            measuredLines.append(measuredLine)

            if let maxY = measuredLine.map({ measuredText in measuredText.backgroundRect.maxY }).max() {
                yOffset = maxY + self.lineSpacing
            } else {
                yOffset += self.minimumLineHeight + self.lineSpacing
            }

        }

        return measuredLines
    }

    // MARK: Private

    private func flip(rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.origin.x,
            y: bounds.height - rect.height - rect.origin.y,
            width: rect.width,
            height: rect.height)
    }

    private func setUpViews() {}

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func update() {
        needsDisplay = true
    }
}
