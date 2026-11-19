import SwiftUI
import AppKit
import SwiftTerm

/// Hosts all open tab terminal views in a single container, toggling visibility for the active tab
/// so switching tabs is instant and never interrupts running shell processes.
struct TerminalHostView: NSViewRepresentable {
    let tabs: [TerminalTab]
    let selectedTabID: UUID?

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0).cgColor
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        let activeViews = Set(tabs.map { ObjectIdentifier($0.terminalView) })

        for subview in container.subviews {
            if !activeViews.contains(ObjectIdentifier(subview)) {
                subview.removeFromSuperview()
            }
        }

        for tab in tabs {
            let tv = tab.terminalView
            if tv.superview !== container {
                tv.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(tv)
                NSLayoutConstraint.activate([
                    tv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    tv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    tv.topAnchor.constraint(equalTo: container.topAnchor),
                    tv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
            }
            let isSelected = (tab.id == selectedTabID)
            tv.isHidden = !isSelected
        }
    }
}
