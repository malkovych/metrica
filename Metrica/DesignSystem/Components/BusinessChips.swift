import SwiftUI

struct BusinessChips: View {
    @Environment(\.bizTheme) private var theme
    @Environment(\.businessMode) private var mode
    let businesses: [Business]
    let selectedID: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(businesses) { biz in
                    let active = biz.id == selectedID
                    Button {
                        onSelect(biz.id)
                    } label: {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(active ? Color.white : theme.green)
                                .frame(width: 7, height: 7)
                            Text("\(biz.emoji) \(biz.name)")
                                .font(.subheadline.weight(.bold))
                            if theme.showsModeBadge {
                                Text(biz.mode == .resto ? "resto" : "ecom")
                                    .font(.system(size: 10, weight: .heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(active ? Color.white.opacity(0.22) : theme.accentSoft(for: biz.mode))
                                    .clipShape(Capsule())
                            } else {
                                Text("· \(biz.sourceType.rawValue.capitalized)")
                                    .font(.caption2.weight(.semibold))
                                    .opacity(0.75)
                            }
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .foregroundStyle(active ? Color.white : theme.text)
                        .background(active ? theme.accent(for: biz.mode) : theme.card)
                        .clipShape(Capsule())
                        .overlay {
                            if !active, let border = theme.cardBorder {
                                Capsule().strokeBorder(border, lineWidth: 1)
                            }
                        }
                        .shadow(
                            color: active && theme.id != .bDarkFintech
                                ? theme.accent(for: biz.mode).opacity(0.26)
                                : theme.shadowCard.color,
                            radius: active ? 14 : theme.shadowCard.radius,
                            y: active ? 8 : theme.shadowCard.y
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("biz_chip_\(biz.id)")
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
        }
    }
}
