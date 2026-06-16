import AppKit
import SwiftUI

struct FluidOnboardingLandingHero<Actions: View>: View {
    @Environment(\.theme) private var theme

    let eyebrow: String
    let title: String
    let accentTitle: String
    let firstDetail: String
    let secondDetail: String
    let actions: Actions

    init(
        eyebrow: String,
        title: String,
        accentTitle: String,
        firstDetail: String,
        secondDetail: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.accentTitle = accentTitle
        self.firstDetail = firstDetail
        self.secondDetail = secondDetail
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 0) {
            FluidOnboardingAppIconMark()
                .padding(.bottom, self.eyebrow.isEmpty ? 40 : 26)

            if !self.eyebrow.isEmpty {
                Text(self.eyebrow)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(4.2)
                    .foregroundStyle(FluidOnboardingLandingColors.blue.opacity(0.72))
                    .textCase(.uppercase)
                    .padding(.bottom, 16)
            }

            VStack(spacing: 4) {
                Text(self.title)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)

                Text(self.accentTitle)
                    .font(.system(size: 50, weight: .semibold))
                    .italic()
                    .foregroundStyle(FluidOnboardingLandingColors.blue)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.76)
            }
            .lineLimit(1)
            .shadow(color: .black.opacity(0.34), radius: 10, x: 0, y: 5)
            .padding(.bottom, 28)

            VStack(spacing: 8) {
                Text(self.firstDetail)
                Text(self.secondDetail)
            }
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.70))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.bottom, 42)

            self.actions
        }
        .padding(.horizontal, self.theme.metrics.onboardingSurface.landing.heroPadding)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct FluidOnboardingLandingBackdrop: View {
    let glowCenter: UnitPoint

    init(glowCenter: UnitPoint = UnitPoint(x: 0.5, y: 0.18)) {
        self.glowCenter = glowCenter
    }

    var body: some View {
        ZStack {
            Color(red: 0.012, green: 0.019, blue: 0.031)

            RadialGradient(
                colors: [
                    FluidOnboardingLandingColors.blue.opacity(0.18),
                    Color(red: 0.014, green: 0.032, blue: 0.068).opacity(0.30),
                    .clear,
                ],
                center: self.glowCenter,
                startRadius: 0,
                endRadius: 620
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.026),
                    .clear,
                ],
                center: .center,
                startRadius: 0,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

private struct FluidOnboardingAppIconMark: View {
    private static let appIconImage: NSImage = NSApplication.shared.applicationIconImage
        ?? NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)

    var body: some View {
        ZStack {
            Circle()
                .fill(FluidOnboardingLandingColors.blue.opacity(0.28))
                .blur(radius: 42)
                .frame(width: 188, height: 188)
                .offset(y: -16)

            FluidOnboardingPortalGlow()
                .offset(y: 58)

            Image(nsImage: Self.appIconImage)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 116, height: 116)
                .shadow(color: Color.black.opacity(0.56), radius: 20, x: 0, y: 15)
                .shadow(color: FluidOnboardingLandingColors.blue.opacity(0.58), radius: 36, x: 0, y: 0)
        }
        .frame(width: 360, height: 176)
        .accessibilityHidden(true)
    }
}

private struct FluidOnboardingPortalGlow: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.74),
                            FluidOnboardingLandingColors.blue.opacity(0.64),
                            FluidOnboardingLandingColors.blue.opacity(0.05),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 112
                    )
                )
                .blur(radius: 7)
                .frame(width: 230, height: 25)

            Ellipse()
                .stroke(FluidOnboardingLandingColors.blue.opacity(0.42), lineWidth: 3)
                .blur(radius: 1.4)
                .frame(width: 326, height: 35)

            Ellipse()
                .stroke(FluidOnboardingLandingColors.blue.opacity(0.24), lineWidth: 1.4)
                .frame(width: 260, height: 22)
        }
    }
}

private enum FluidOnboardingLandingColors {
    static let blue = Color(red: 0.10, green: 0.46, blue: 1.0)
    static let buttonBlue = Color(red: 0.08, green: 0.43, blue: 1.0)
    static let buttonBlueHighlight = Color(red: 0.24, green: 0.58, blue: 1.0)
}

private struct OnboardingSelectableSurfaceModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let isSelected: Bool
    let cornerRadius: CGFloat?
    let padding: CGFloat?
    let selectedBorderOpacity: Double?

    func body(content: Content) -> some View {
        let surface = self.theme.metrics.onboardingSurface
        let radius = self.cornerRadius ?? surface.optionCornerRadius
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .padding(self.padding ?? surface.optionPadding)
            .background(
                shape
                    .fill(self.theme.palette.cardBackground.opacity(
                        self.isSelected ? surface.selectedFillOpacity : surface.normalFillOpacity
                    ))
                    .overlay(
                        shape.stroke(
                            self.isSelected
                                ? self.theme.palette.accent.opacity(self.selectedBorderOpacity ?? surface.selectedBorderOpacity)
                                : self.theme.palette.cardBorder.opacity(surface.normalBorderOpacity),
                            lineWidth: 1
                        )
                    )
            )
            .contentShape(shape)
    }
}

private struct OnboardingEditorSurfaceModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        let surface = self.theme.metrics.onboardingSurface
        let radius = self.cornerRadius ?? surface.editorCornerRadius
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .padding(surface.editorPadding)
            .background(
                shape
                    .fill(self.theme.palette.cardBackground)
                    .overlay(
                        shape.stroke(self.theme.palette.cardBorder.opacity(surface.editorBorderOpacity), lineWidth: 1)
                    )
            )
    }
}

private struct OnboardingProminentButtonModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let controlSize: ControlSize?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let controlSize {
            content
                .buttonStyle(.borderedProminent)
                .controlSize(controlSize)
                .tint(self.theme.palette.accent)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .tint(self.theme.palette.accent)
        }
    }
}

private struct OnboardingGlowButtonModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    let controlSize: ControlSize?

    func body(content: Content) -> some View {
        let isLarge = self.controlSize == .large

        content
            .font(.system(size: isLarge ? 18 : 14, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, isLarge ? 52 : 24)
            .padding(.vertical, isLarge ? 15 : 9)
            .frame(minWidth: isLarge ? 236 : 0)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                FluidOnboardingLandingColors.buttonBlueHighlight,
                                FluidOnboardingLandingColors.buttonBlue,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: FluidOnboardingLandingColors.blue.opacity(self.isHovered ? 0.56 : 0.34),
                        radius: self.isHovered ? 24 : 16,
                        x: 0,
                        y: 8
                    )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .contentShape(Capsule())
            .buttonStyle(.plain)
            .onHover { hovering in
                self.isHovered = hovering
            }
            .animation(.easeOut(duration: 0.16), value: self.isHovered)
    }
}

private struct OnboardingSecondaryButtonModifier: ViewModifier {
    let controlSize: ControlSize?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let controlSize {
            content
                .buttonStyle(.bordered)
                .controlSize(controlSize)
        } else {
            content
                .buttonStyle(.bordered)
        }
    }
}

extension View {
    func fluidOnboardingSelectableSurface(
        isSelected: Bool,
        cornerRadius: CGFloat? = nil,
        padding: CGFloat? = nil,
        selectedBorderOpacity: Double? = nil
    ) -> some View {
        self.modifier(OnboardingSelectableSurfaceModifier(
            isSelected: isSelected,
            cornerRadius: cornerRadius,
            padding: padding,
            selectedBorderOpacity: selectedBorderOpacity
        ))
    }

    func fluidOnboardingEditorSurface(cornerRadius: CGFloat? = nil) -> some View {
        self.modifier(OnboardingEditorSurfaceModifier(cornerRadius: cornerRadius))
    }

    func fluidOnboardingProminentButton(controlSize: ControlSize? = nil) -> some View {
        self.modifier(OnboardingProminentButtonModifier(controlSize: controlSize))
    }

    func fluidOnboardingGlowButton(controlSize: ControlSize? = nil) -> some View {
        self.modifier(OnboardingGlowButtonModifier(controlSize: controlSize))
    }

    func fluidOnboardingSecondaryButton(controlSize: ControlSize? = nil) -> some View {
        self.modifier(OnboardingSecondaryButtonModifier(controlSize: controlSize))
    }
}
