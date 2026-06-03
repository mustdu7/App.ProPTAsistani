import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - AppointmentDisplaying
protocol AppointmentDisplaying {
    var clientName:    String { get }
    var timeString:    String { get }
    var durationString: String { get }
    var type:          String { get }
    var isPast:        Bool   { get }
}

// MARK: - typeColor
func typeColor(for type: String) -> Color {
    switch type {
    case "Güç Antrenmanı": return Color(hex: "#5C6BC0")
    case "Kardio":         return Color(hex: "#E05C5C")
    case "Fonksiyonel":    return Color(hex: "#5CB8E0")
    case "Pilates":        return Color(hex: "#9B5CE0")
    default:               return Color(hex: "#5C6BC0")
    }
}

// MARK: - Shared UI Helpers

/// Standart kart arka planı + border
extension View {
    func styledCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(Color(hex: "#1E1E22"))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
    }
}

/// İnce ayraç çizgisi
struct ThinDivider: View {
    var body: some View {
        Rectangle().fill(Color(hex: "#2A2A2D")).frame(height: 0.5)
    }
}

// MARK: - Swipeable Row

struct SwipeAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let handler: () -> Void
}

struct SwipeableRow<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var leadingActions: [SwipeAction] = []
    var trailingActions: [SwipeAction] = []

    @State private var offset: CGFloat = 0
    @GestureState private var isDragging = false

    private let actionWidth: CGFloat = 70

    private var leadingWidth: CGFloat { CGFloat(leadingActions.count) * actionWidth }
    private var trailingWidth: CGFloat { CGFloat(trailingActions.count) * actionWidth }

    var body: some View {
        ZStack {
            // Trailing actions (sola kaydırınca görünür)
            if !trailingActions.isEmpty {
                HStack(spacing: 0) {
                    Spacer()
                    ForEach(trailingActions) { action in
                        Button {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                action.handler()
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 18))
                                Text(action.label)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .frame(width: actionWidth)
                            .frame(maxHeight: .infinity)
                        }
                        .buttonStyle(.plain)
                        .background(action.color)
                    }
                }
            }

            // Leading actions (sağa kaydırınca görünür)
            if !leadingActions.isEmpty {
                HStack(spacing: 0) {
                    ForEach(leadingActions) { action in
                        Button {
                            close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                action.handler()
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 18))
                                Text(action.label)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .frame(width: actionWidth)
                            .frame(maxHeight: .infinity)
                        }
                        .buttonStyle(.plain)
                        .background(action.color)
                    }
                    Spacer()
                }
            }

            // Ana içerik
            content()
                .background(Color(hex: "#141416"))
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 16)
                        .updating($isDragging) { _, state, _ in state = true }
                        .onChanged { value in
                            let t = value.translation.width
                            if t < 0 && !trailingActions.isEmpty {
                                offset = max(t, -trailingWidth - 20)
                            } else if t > 0 && !leadingActions.isEmpty {
                                offset = min(t, leadingWidth + 20)
                            }
                        }
                        .onEnded { value in
                            let t = value.translation.width
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if t < -(actionWidth * 0.4) && !trailingActions.isEmpty {
                                    offset = -trailingWidth
                                } else if t > (actionWidth * 0.4) && !leadingActions.isEmpty {
                                    offset = leadingWidth
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
                .onChange(of: isDragging) { _, dragging in
                    if !dragging && offset != 0 && offset != -trailingWidth && offset != leadingWidth {
                        close()
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
        }
    }
}
