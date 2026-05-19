import SwiftUI

/// A compact sparkline (filled area chart) for displaying time-series data.
///
/// - Accepts up to 60 data points in the range 0–100.
/// - Draws subtle grid lines at 25 %, 50 %, and 75 %.
/// - Uses a `Canvas` for efficient rendering without creating per-point views.
struct MiniGraphView: View {

    /// The data series. Values should be in 0–100. Newest value at the end.
    let data: [Double]

    /// Fill/stroke colour for the sparkline.
    let color: Color

    // Fixed display size as specified in the requirements.
    var body: some View {
        Canvas { context, size in
            drawGrid(context: context, size: size)
            drawArea(context: context, size: size)
            drawLine(context: context, size: size)
        }
        .frame(width: 120, height: 36)
        .background(Color.black.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Drawing

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let gridColor = Color.primary.opacity(0.08)
        let levels: [Double] = [0.25, 0.50, 0.75]

        for level in levels {
            let y = size.height * (1.0 - level)
            var path = Path()
            path.move(to:   CGPoint(x: 0,          y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }
    }

    private func drawArea(context: GraphicsContext, size: CGSize) {
        guard data.count >= 2 else { return }
        var path = Path()
        let pts = points(for: data, in: size)

        path.move(to: CGPoint(x: pts[0].x, y: size.height))
        for pt in pts {
            path.addLine(to: pt)
        }
        path.addLine(to: CGPoint(x: pts.last!.x, y: size.height))
        path.closeSubpath()

        context.fill(path, with: .color(color.opacity(0.25)))
    }

    private func drawLine(context: GraphicsContext, size: CGSize) {
        guard data.count >= 2 else { return }
        var path = Path()
        let pts = points(for: data, in: size)

        path.move(to: pts[0])
        for pt in pts.dropFirst() {
            path.addLine(to: pt)
        }
        context.stroke(path, with: .color(color), lineWidth: 1.5)
    }

    // MARK: - Helpers

    private func points(for values: [Double], in size: CGSize) -> [CGPoint] {
        let count = values.count
        return values.enumerated().map { index, value in
            let x = count < 2
                ? 0.0
                : CGFloat(index) / CGFloat(count - 1) * size.width
            let clampedValue = max(0.0, min(100.0, value))
            let y = size.height * (1.0 - clampedValue / 100.0)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MiniGraphView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = (0..<60).map { i in
            50.0 + 30.0 * sin(Double(i) * 0.3)
        }
        HStack(spacing: 12) {
            MiniGraphView(data: sampleData, color: .green)
            MiniGraphView(data: sampleData.map { 100 - $0 }, color: .blue)
        }
        .padding()
        .background(Color.black)
    }
}
#endif
