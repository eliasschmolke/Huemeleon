//
//  ColorInputView.swift
//  Huemeleon
//
//  Small sheet to enter an exact color: HSV wheel + HEX and RGB input fields.
//

import SwiftUI

struct ColorInputView: View {
    @State private var color: PickedColor
    @State private var hexText: String
    @State private var rText: String
    @State private var gText: String
    @State private var bText: String

    let onAdd: (PickedColor) -> Void
    let onCancel: () -> Void

    init(initial: PickedColor = PickedColor(red: 1, green: 0, blue: 0),
         onAdd: @escaping (PickedColor) -> Void, onCancel: @escaping () -> Void) {
        _color = State(initialValue: initial)
        let v = initial.rgb255
        _hexText = State(initialValue: String(initial.hex.dropFirst()))
        _rText = State(initialValue: "\(v.r)")
        _gText = State(initialValue: "\(v.g)")
        _bText = State(initialValue: "\(v.b)")
        self.onAdd = onAdd
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Color").font(.headline)

            ColorWheelView(color: color) { setColor($0) }
                .frame(width: 200)

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.swiftUIColor).frame(width: 46, height: 46)
                    .overlay { RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.black.opacity(0.15)) }
                HStack(spacing: 6) {
                    Text("HEX").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).frame(width: 34, alignment: .leading)
                    TextField("RRGGBB", text: $hexText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit { applyHex() }
                }
            }

            HStack(spacing: 8) {
                rgbField("R", $rText)
                rgbField("G", $gText)
                rgbField("B", $bText)
            }

            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Button("Add") { onAdd(color) }.buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func rgbField(_ label: String, _ text: Binding<String>) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            TextField("0", text: text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .onSubmit { applyRGB() }
        }
    }

    private func setColor(_ c: PickedColor) {
        color = c
        syncFields()
    }

    private func syncFields() {
        hexText = String(color.hex.dropFirst())
        let v = color.rgb255
        rText = "\(v.r)"; gText = "\(v.g)"; bText = "\(v.b)"
    }

    private func applyHex() {
        if let c = PickedColor(hex: hexText) { color = c; syncFields() }
    }

    private func applyRGB() {
        func clamp(_ s: String) -> Double { Double(min(max(Int(s) ?? 0, 0), 255)) / 255 }
        color = PickedColor(red: clamp(rText), green: clamp(gText), blue: clamp(bText))
        syncFields()
    }
}
