//
//  GlassSegmented.swift
//  Huemeleon
//
//  Reusable Apple-style glass segmented slider (frosted pill slides between
//  segments). Used for Pick/Palette and for the menu-bar Colors/Palettes toggle.
//

import SwiftUI

struct GlassSegmented<T: Hashable>: View {
    let options: [T]
    let title: (T) -> String
    @Binding var selection: T
    var width: CGFloat? = nil
    var height: CGFloat = 28

    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { opt in
                let selected = selection == opt
                Text(title(opt))
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(selected ? .primary : .secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selected {
                            Capsule()
                                .fill(.regularMaterial)
                                .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
                                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "pill", in: ns)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture { withAnimation(.snappy(duration: 0.3)) { selection = opt } }
            }
        }
        .padding(3)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .background(Capsule().fill(.black.opacity(0.08)))
    }
}
