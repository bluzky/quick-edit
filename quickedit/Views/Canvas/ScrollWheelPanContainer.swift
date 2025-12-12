//
//  ScrollWheelPanContainer.swift
//  quickedit
//
//  NSViewRepresentable that intercepts scroll wheel events for canvas panning
//

import SwiftUI
import AppKit

/// Hosts SwiftUI content and intercepts scroll wheel events to drive panning
struct ScrollWheelPanContainer<Content: View>: NSViewRepresentable {
    let onScroll: (CGPoint) -> Void
    let content: Content

    init(onScroll: @escaping (CGPoint) -> Void, @ViewBuilder content: () -> Content) {
        self.onScroll = onScroll
        self.content = content()
    }

    func makeNSView(context: Context) -> ScrollWheelPanHostingView<Content> {
        let host = ScrollWheelPanHostingView(rootView: content)
        host.onScroll = onScroll
        return host
    }

    func updateNSView(_ nsView: ScrollWheelPanHostingView<Content>, context: Context) {
        nsView.onScroll = onScroll
        nsView.rootView = content
    }
}

final class ScrollWheelPanHostingView<Content: View>: NSHostingView<Content> {
    var onScroll: ((CGPoint) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        guard event.phase != .ended else { return }
        onScroll?(CGPoint(x: event.scrollingDeltaX, y: event.scrollingDeltaY))
        // Avoid super to keep the event from trying to scroll enclosing views
    }
}
