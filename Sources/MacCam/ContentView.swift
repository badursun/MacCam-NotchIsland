import SwiftUI

struct ContentView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var settings: SettingsManager
    let menuBarHeight: CGFloat
    var onClose: () -> Void

    private let sideGap: CGFloat = 20
    private let curveHeight: CGFloat = 20
    private let neckHeight: CGFloat = 0

    @State private var revealProgress: CGFloat = 0
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: neckHeight + curveHeight + 14)

            VStack(spacing: 12) {
                if cameraManager.isAuthorized {
                    ZStack {
                        CameraPreviewView(session: cameraManager.session)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        // Flash effect on capture
                        if cameraManager.showFlash {
                            Color.white
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .transition(.opacity)
                        }

                        if cameraManager.showSaveConfirmation {
                            VStack {
                                Spacer()
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Kaydedildi!")
                                        .font(.caption).bold()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Capsule())
                                .padding(.bottom, 8)
                            }
                            .transition(.opacity)
                        }
                    }
                    .frame(height: 220)

                    if showSettings {
                        // Settings panel
                        VStack(spacing: 14) {
                            // Save location
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Kayit Klasoru")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                HStack {
                                    Text(settings.saveDirectory.lastPathComponent)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Degistir") {
                                        settings.chooseSaveDirectory()
                                    }
                                    .font(.system(size: 11))
                                    .buttonStyle(.bordered)
                                    .tint(.white)
                                }
                            }

                            // Backdrop toggle
                            HStack {
                                Text("Backdrop Blur")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $settings.backdropEnabled)
                                    .toggleStyle(.switch)
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        // Buttons row:  o  O  o
                        HStack(spacing: 20) {
                            // Settings button (small)
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSettings = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .buttonStyle(.plain)

                            // Capture button (large)
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

                            // Close button (small)
                            Button(action: { onClose() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
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

                if showSettings {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettings = false
                        }
                    }) {
                        Text("Tamam")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
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

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + nH))

        path.addArc(
            center: CGPoint(x: rect.maxX, y: rect.minY + nH + cH),
            radius: gap,
            startAngle: .degrees(270),
            endAngle: .degrees(180),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.maxX - gap, y: effectiveBottom - bR))

        if bR > 0.5 {
            path.addArc(
                center: CGPoint(x: rect.maxX - gap - bR, y: effectiveBottom - bR),
                radius: bR,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }

        path.addLine(to: CGPoint(x: rect.minX + gap + bR, y: effectiveBottom))

        if bR > 0.5 {
            path.addArc(
                center: CGPoint(x: rect.minX + gap + bR, y: effectiveBottom - bR),
                radius: bR,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }

        path.addLine(to: CGPoint(x: rect.minX + gap, y: rect.minY + nH + cH))

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
