//
//  ColorWheelView.swift
//  Huemeleon
//
//  HSV color wheel (macOS color-picker style): hue around the ring, saturation
//  outward, brightness via the slider. A marker shows the current color. Used in
//  the manual color-input sheet.
//

import SwiftUI

struct ColorWheelView: View {
    var color: PickedColor
    var onChange: (PickedColor) -> Void

    private var hsv: (h: Double, s: Double, v: Double) { color.hsvRaw }

    private var hueColors: [Color] {
        stride(from: 0, through: 360, by: 30).map {
            Color(hue: ($0.truncatingRemainder(dividingBy: 360)) / 360, saturation: 1, brightness: 1)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                let radius = side / 2
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let angle = hsv.h * .pi / 180
                let marker = CGPoint(x: center.x + cos(angle) * radius * hsv.s,
                                     y: center.y + sin(angle) * radius * hsv.s)

                ZStack {
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(colors: hueColors), center: .center))
                        .overlay(
                            RadialGradient(gradient: Gradient(colors: [.white, .white.opacity(0)]),
                                           center: .center, startRadius: 0, endRadius: radius)
                        )
                        .overlay(Circle().fill(.black).opacity(1 - hsv.v))
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.black.opacity(0.12)))
                        .frame(width: side, height: side)
                        .position(center)

                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .shadow(radius: 1)
                        .position(marker)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in handleDrag(g.location, center: center, radius: radius) }
                )
            }
            .aspectRatio(1, contentMode: .fit)

            HStack(spacing: 8) {
                Image(systemName: "sun.min").foregroundStyle(.secondary).font(.caption)
                Slider(value: Binding(
                    get: { hsv.v },
                    set: { onChange(PickedColor(hue: hsv.h, saturation: hsv.s, value: $0)) }
                ), in: 0...1)
                Image(systemName: "sun.max").foregroundStyle(.secondary).font(.caption)
            }
        }
    }

    private func handleDrag(_ location: CGPoint, center: CGPoint, radius: CGFloat) {
        let dx = location.x - center.x, dy = location.y - center.y
        var deg = atan2(dy, dx) * 180 / .pi
        if deg < 0 { deg += 360 }
        let dist = min(sqrt(dx * dx + dy * dy) / radius, 1)
        onChange(PickedColor(hue: Double(deg), saturation: Double(dist), value: hsv.v))
    }
}
