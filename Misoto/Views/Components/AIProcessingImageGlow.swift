//
//  AIProcessingImageGlow.swift
//  Misoto
//
//  Outer aura behind the image — rotating spectrum on the photo border.
//

import SwiftUI

struct AIProcessingImageGlow: View {
    let cornerRadius: CGFloat
    var isActive: Bool = true

    /// Seconds for one full lap of the rotating spectrum.
    private let lapDuration: Double = 6.4
    private let fadeDuration: Double = 0.5

    private enum Edge {
        static let perimeterLineWidth: CGFloat = 6
        static let perimeterBlur: CGFloat = 6
        static let rotatingLineWidthSoft: CGFloat = 10
        static let rotatingLineWidthCore: CGFloat = 4
        static let rotatingBlurSoft: CGFloat = 7
        static let rotatingBlurCore: CGFloat = 3
        static let sweepingLineWidth: CGFloat = 8
        static let sweepingBlur: CGFloat = 5
        static let layerStrength: Double = 0.72
    }

    @State private var displayOpacity: Double = 0

    private static let highlightPink = Color(red: 1.0, green: 0.34, blue: 0.58)
    private static let highlightMagenta = Color(red: 0.96, green: 0.22, blue: 0.82)
    private static let highlightBlue = Color(red: 0.28, green: 0.55, blue: 1.0)
    private static let highlightPurple = Color(red: 0.58, green: 0.32, blue: 1.0)
    private static let highlightOrange = Color(red: 1.0, green: 0.52, blue: 0.36)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let rotation = (elapsed.truncatingRemainder(dividingBy: lapDuration) / lapDuration) * 360.0

            ZStack {
                outerRing(
                    gradient: perimeterRingGradient,
                    lineWidth: Edge.perimeterLineWidth,
                    blur: Edge.perimeterBlur,
                    opacity: 0.32
                )
                outerRing(
                    gradient: rotatingSpectrumGradient(rotation: rotation),
                    lineWidth: Edge.rotatingLineWidthSoft,
                    blur: Edge.rotatingBlurSoft,
                    opacity: 0.5
                )
                outerRing(
                    gradient: rotatingSpectrumGradient(rotation: rotation),
                    lineWidth: Edge.rotatingLineWidthCore,
                    blur: Edge.rotatingBlurCore,
                    opacity: 0.65
                )
                outerRing(
                    gradient: sweepingBandGradient(rotation: rotation),
                    lineWidth: Edge.sweepingLineWidth,
                    blur: Edge.sweepingBlur,
                    opacity: 0.45
                )
            }
            .opacity(Edge.layerStrength)
        }
        .opacity(displayOpacity)
        .onAppear {
            setDisplayedOpacity(isActive, animated: isActive)
        }
        .onChange(of: isActive) { _, active in
            setDisplayedOpacity(active, animated: true)
        }
        .accessibilityHidden(true)
    }

    private var glowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private func setDisplayedOpacity(_ active: Bool, animated: Bool) {
        let target = active ? 1.0 : 0.0
        if animated {
            withAnimation(.easeInOut(duration: fadeDuration)) {
                displayOpacity = target
            }
        } else {
            displayOpacity = target
        }
    }

    // MARK: - Outer rings

    private var perimeterRingGradient: AngularGradient {
        AngularGradient(
            colors: [
                Self.highlightPink.opacity(0.55),
                Self.highlightMagenta.opacity(0.5),
                Self.highlightBlue.opacity(0.55),
                Self.highlightPurple.opacity(0.5),
                Self.highlightOrange.opacity(0.5),
                Self.highlightPink.opacity(0.55)
            ],
            center: .center
        )
    }

    private func outerRing(
        gradient: AngularGradient,
        lineWidth: CGFloat,
        blur: CGFloat,
        opacity: Double
    ) -> some View {
        glowShape
            .stroke(gradient, lineWidth: lineWidth)
            .blur(radius: blur)
            .opacity(opacity)
    }

    // MARK: - Rotating spectrum

    private func rotatingSpectrumGradient(rotation: Double) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Self.highlightPink, location: 0.0),
                .init(color: Self.highlightMagenta, location: 0.2),
                .init(color: Self.highlightBlue, location: 0.4),
                .init(color: Self.highlightPurple, location: 0.6),
                .init(color: Self.highlightOrange, location: 0.8),
                .init(color: Self.highlightPink, location: 1.0)
            ]),
            center: .center,
            angle: .degrees(rotation)
        )
    }

    private func sweepingBandGradient(rotation: Double) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.06),
                .init(color: Self.highlightPink.opacity(0.15), location: 0.12),
                .init(color: Self.highlightPink.opacity(0.4), location: 0.18),
                .init(color: Self.highlightMagenta.opacity(0.58), location: 0.22),
                .init(color: Self.highlightBlue.opacity(0.75), location: 0.28),
                .init(color: Self.highlightPurple.opacity(0.82), location: 0.34),
                .init(color: Self.highlightOrange.opacity(0.88), location: 0.40),
                .init(color: Self.highlightBlue.opacity(0.7), location: 0.46),
                .init(color: Self.highlightPink.opacity(0.75), location: 0.52),
                .init(color: Self.highlightMagenta.opacity(0.5), location: 0.58),
                .init(color: Self.highlightPurple.opacity(0.32), location: 0.64),
                .init(color: Self.highlightOrange.opacity(0.18), location: 0.72),
                .init(color: .clear, location: 0.86),
                .init(color: .clear, location: 1.0)
            ]),
            center: .center,
            angle: .degrees(rotation)
        )
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color(.systemGroupedBackground)
        ZStack {
            AIProcessingImageGlow(cornerRadius: 16, isActive: true)
                .frame(width: 280, height: 280)
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(14)
    }
    .padding()
}
#endif
