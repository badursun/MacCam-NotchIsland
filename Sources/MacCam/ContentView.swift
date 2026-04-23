import SwiftUI

struct ContentView: View {
    @ObservedObject var cameraManager: CameraManager
    let menuBarHeight: CGFloat

    private let sideGap: CGFloat = 20
    private let curveHeight: CGFloat = 20
    private let neckHeight: CGFloat = 0

    @State private var revealProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: neckHeight + curveHeight + 14)

            VStack(spacing: 12) {
                if cameraManager.isAuthorized {
                    ZStack {
                        CameraPreviewView(session: cameraManager.session)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        if cameraManager.showSaveConfirmation {
                            VStack {
                                Spacer()
                                Text("Kaydedildi!")
                                    .font(.caption).bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.8))
                                    .clipShape(Capsule())
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .frame(height: 220)

                    Button(action: { cameraManager.capturePhoto() }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 2.5)
                                .frame(width: 50, height: 50)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                        Text("Kamera izni gerekli")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(height: 220)
                }

                Text("maccam")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, sideGap + 10)
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
        .background(Color.black)
        .clipShape(
            DynamicIslandShape(
                neckHeight: neckHeight,
                sideGap: sideGap,
                curveHeight: curveHeight,
                bottomRadius: 22,
                revealProgress: revealProgress
            )
        )
        .onAppear {
            withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)) {
                revealProgress = 1.0
            }
        }
    }
}

struct DynamicIslandShape: Shape {
    var neckHeight: CGFloat
    var sideGap: CGFloat
    var curveHeight: CGFloat
    var bottomRadius: CGFloat
    var revealProgress: CGFloat

    var animatableData: CGFloat {
        get { revealProgress }
        set { revealProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let gap = sideGap
        let cH = curveHeight
        let nH = neckHeight

        let topZone = nH + cH
        let bodySpace = rect.height - topZone
        let revealedBody = bodySpace * revealProgress
        let effectiveBottom = rect.minY + topZone + revealedBody
        let bR = min(bottomRadius, revealedBody * 0.5)

        var path = Path()

        // Wide flat top
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right edge down to neck bottom
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + nH))

        // Right concave curve (wide → narrow)
        path.addArc(
            center: CGPoint(x: rect.maxX, y: rect.minY + nH + cH),
            radius: gap,
            startAngle: .degrees(270),
            endAngle: .degrees(180),
            clockwise: true
        )

        // Right body edge — down to effective bottom
        path.addLine(to: CGPoint(x: rect.maxX - gap, y: effectiveBottom - bR))

        // Bottom-right corner
        if bR > 0.5 {
            path.addArc(
                center: CGPoint(x: rect.maxX - gap - bR, y: effectiveBottom - bR),
                radius: bR,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + gap + bR, y: effectiveBottom))

        // Bottom-left corner
        if bR > 0.5 {
            path.addArc(
                center: CGPoint(x: rect.minX + gap + bR, y: effectiveBottom - bR),
                radius: bR,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }

        // Left body edge — up to curve
        path.addLine(to: CGPoint(x: rect.minX + gap, y: rect.minY + nH + cH))

        // Left concave curve (narrow → wide)
        path.addArc(
            center: CGPoint(x: rect.minX, y: rect.minY + nH + cH),
            radius: gap,
            startAngle: .degrees(0),
            endAngle: .degrees(270),
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}
