//
//  ColorValuesView.swift
//  Huemeleon
//
//  Color values as copyable rows: HEX, RGB, RGBA, HSL, CMYK. When no color is set
//  every value shows "---". Copying swaps the trailing icon to a checkmark.
//

import SwiftUI

struct ColorValuesView: View {
    let color: PickedColor?

    @State private var copied: String?
    @State private var token = 0

    private var hasColor: Bool { color != nil }

    var body: some View {
        VStack(spacing: 0) {
            row("HEX", hexStr)
            Divider()
            row("RGB", rgbStr)
            Divider()
            row("RGBA", rgbaStr)
            Divider()
            row("HSL", hslStr)
            Divider()
            row("CMYK", cmykStr)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.black.opacity(0.08)))
    }

    // MARK: Value strings

    private var hexStr: String { color?.hex ?? "---" }
    private var rgbStr: String {
        guard let v = color?.rgb255 else { return "---" }
        return "\(v.r)  \(v.g)  \(v.b)"
    }
    private var rgbaStr: String {
        guard let v = color?.rgb255 else { return "---" }
        return "rgba(\(v.r), \(v.g), \(v.b), 1)"
    }
    private var hslStr: String {
        guard let v = color?.hsl else { return "---" }
        return "\(v.h)°  \(v.s)%  \(v.l)%"
    }
    private var cmykStr: String {
        guard let v = color?.cmyk else { return "---" }
        return "\(v.c)  \(v.m)  \(v.y)  \(v.k)%"
    }

    // MARK: Row

    private func row(_ label: String, _ value: String) -> some View {
        let isCopied = copied == label
        return Button { copy(label, value) } label: {
            HStack(spacing: 8) {
                Text(label)
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                    .frame(width: 46, alignment: .leading)
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(hasColor ? .primary : .secondary)
                    .lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(isCopied ? AnyShapeStyle(Color.green) : AnyShapeStyle(.tertiary))
                    .frame(width: 14, height: 14)
                    .contentTransition(.symbolEffect(.replace))
                    .opacity(hasColor ? 1 : 0)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!hasColor)
        .help(hasColor ? "Copy \(value)" : "Copy")
        .animation(.easeInOut(duration: 0.2), value: isCopied)
    }

    private func copy(_ label: String, _ value: String) {
        guard hasColor else { return }
        Clipboard.copyString(value)
        copied = label
        token += 1
        let current = token
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if token == current { copied = nil }
        }
    }
}
