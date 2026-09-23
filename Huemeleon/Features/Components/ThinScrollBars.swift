//
//  ThinScrollBars.swift
//  Huemeleon
//
//  Forces the enclosing NSScrollView to thin overlay scrollers. Applies the style
//  as soon as the view enters the hierarchy to avoid a brief thick-bar flash.
//

import SwiftUI
import AppKit

private final class ScrollerStyleNSView: NSView {
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        apply()
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        apply()
    }
    private func apply() {
        var cur: NSView? = self
        while let c = cur {
            if let scroll = c.enclosingScrollView {
                scroll.scrollerStyle = .overlay
                scroll.verticalScroller?.controlSize = .mini
                scroll.horizontalScroller?.controlSize = .mini
                break
            }
            cur = c.superview
        }
    }
}

private struct ThinScrollBars: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { ScrollerStyleNSView(frame: .zero) }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    /// Makes the enclosing ScrollView's scrollbars thin (overlay style).
    func thinScrollBars() -> some View {
        background(ThinScrollBars().frame(width: 0, height: 0))
    }
}
