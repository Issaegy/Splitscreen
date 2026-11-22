import SwiftUI

/// Zwei Bereiche nebeneinander (oder übereinander) mit verschiebbarem Trenner
/// in der Mitte – wie der klassische Splitscreen auf dem iPad.
struct SplitLayout<First: View, Second: View>: View {
    @Binding var fraction: Double
    let vertical: Bool
    let first: First
    let second: Second

    @State private var startFraction: Double?

    private let handleThickness: CGFloat = 18
    private let minFraction = 0.15
    private let maxFraction = 0.85

    init(
        fraction: Binding<Double>,
        vertical: Bool,
        @ViewBuilder first: () -> First,
        @ViewBuilder second: () -> Second
    ) {
        _fraction = fraction
        self.vertical = vertical
        self.first = first()
        self.second = second()
    }

    var body: some View {
        GeometryReader { geo in
            let total = vertical ? geo.size.height : geo.size.width
            let available = max(total - handleThickness, 1)
            let firstLength = available * fraction
            let layout = vertical
                ? AnyLayout(VStackLayout(spacing: 0))
                : AnyLayout(HStackLayout(spacing: 0))

            layout {
                first
                    .frame(
                        width: vertical ? nil : firstLength,
                        height: vertical ? firstLength : nil
                    )

                SplitHandle(vertical: vertical, isDragging: startFraction != nil)
                    .frame(
                        width: vertical ? nil : handleThickness,
                        height: vertical ? handleThickness : nil
                    )
                    .gesture(dragGesture(available: available))
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.3)) { fraction = 0.5 }
                    }

                second
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func dragGesture(available: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let start = startFraction ?? fraction
                if startFraction == nil { startFraction = fraction }
                let delta = vertical ? value.translation.height : value.translation.width
                fraction = min(max(start + delta / available, minFraction), maxFraction)
            }
            .onEnded { _ in
                startFraction = nil
                // Leicht in der Mitte einrasten.
                if abs(fraction - 0.5) < 0.03 {
                    withAnimation(.spring(duration: 0.2)) { fraction = 0.5 }
                }
            }
    }
}

private struct SplitHandle: View {
    let vertical: Bool
    let isDragging: Bool

    var body: some View {
        ZStack {
            Color.clear
            Capsule()
                .fill(isDragging ? Color.accentColor : Color.secondary.opacity(0.45))
                .frame(width: vertical ? 48 : 5, height: vertical ? 5 : 48)
                .scaleEffect(isDragging ? 1.15 : 1)
        }
        .contentShape(Rectangle())
        .hoverEffect(.highlight)
        .animation(.easeOut(duration: 0.15), value: isDragging)
        .accessibilityLabel("Trenner – ziehen, um die Größe zu ändern")
    }
}
