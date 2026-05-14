//
//  LevelProgressView.swift
//  Misoto
//

import SwiftUI

struct LevelProgressView: View {
    let progress: XPLevelProgress
    let title: String
    var minimized: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var displayedProgressPercent: Double = 0
    @State private var displayedLevel: Int = 1
    @State private var hasInitializedProgress = false
    @State private var progressAnimationTask: Task<Void, Never>?
    
    private var clampedTargetProgressPercent: Double {
        min(100, max(0, progress.progressPercent))
    }

    var body: some View {
        Group {
            if minimized {
                HStack(spacing: 10) {
                    Text(String(format: LocalizedString("Lv %d", comment: "Compact level label"), progress.currentLevel))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.25))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.34, green: 0.84, blue: 1.0),
                                            Color(red: 0.19, green: 0.56, blue: 0.96)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geo.size.width * CGFloat(displayedProgressPercent / 100.0)))
                        }
                    }
                    .frame(height: 10)
                    
                    Text(title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    colorScheme == .dark
                    ? Color(red: 0.03, green: 0.1, blue: 0.24).opacity(0.28)
                    : Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.08, green: 0.2, blue: 0.43), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.92) : .primary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(String(format: LocalizedString("LV %d", comment: "Current level compact"), progress.currentLevel))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(LocalizedString("XP", comment: "XP short label"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.86) : .secondary)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.black.opacity(0.38))
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.34, green: 0.84, blue: 1.0),
                                                    Color(red: 0.19, green: 0.56, blue: 0.96)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(8, geo.size.width * CGFloat(displayedProgressPercent / 100.0)))
                                    
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    
                                }
                            }
                            .frame(height: 11)
                        }
                        
                        HStack {
                            Text(String(format: LocalizedString("%d / %d XP", comment: "Current and next level xp"), progress.totalXP, progress.nextLevelXP))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.88) : .primary)
                            Spacer()
                    Text(String(format: LocalizedString("%d to next level", comment: "XP needed compact"), progress.xpNeededForNextLevel))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.74) : .secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            colorScheme == .dark
                            ? Color.white.opacity(0.18)
                            : Color(red: 0.08, green: 0.2, blue: 0.43),
                            lineWidth: 1
                        )
                )
                .background(
                    Group {
                        if colorScheme == .dark {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.08, green: 0.2, blue: 0.43),
                                    Color(red: 0.03, green: 0.1, blue: 0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color(.systemBackground)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: colorScheme == .dark ? Color.blue.opacity(0.25) : .clear, radius: 6, x: 0, y: 2)
            }
        }
        .onAppear {
            initializeProgressIfNeeded()
        }
        .onChange(of: progress.totalXP) { _, _ in
            startProgressAnimation()
        }
        .onDisappear {
            progressAnimationTask?.cancel()
            progressAnimationTask = nil
        }
    }
    
    private func initializeProgressIfNeeded() {
        guard !hasInitializedProgress else { return }
        hasInitializedProgress = true
        displayedLevel = progress.currentLevel
        displayedProgressPercent = clampedTargetProgressPercent
    }
    
    private func startProgressAnimation() {
        initializeProgressIfNeeded()
        
        progressAnimationTask?.cancel()
        let targetLevel = progress.currentLevel
        let targetPercent = clampedTargetProgressPercent
        
        progressAnimationTask = Task {
            if targetLevel > displayedLevel {
                withAnimation(.easeOut(duration: 0.28)) {
                    displayedProgressPercent = 100
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                withAnimation(.linear(duration: 0.12)) {
                    displayedProgressPercent = 0
                }
                displayedLevel = targetLevel
                try? await Task.sleep(nanoseconds: 140_000_000)
                
                withAnimation(.easeOut(duration: 0.4)) {
                    displayedProgressPercent = targetPercent
                }
            } else {
                displayedLevel = targetLevel
                withAnimation(.easeOut(duration: 0.4)) {
                    displayedProgressPercent = targetPercent
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    LevelProgressView(
        progress: XPLevelCalculator.getLevelProgress(totalXP: 765),
        title: XPLevelCalculator.getLevelTitle(level: 8)
    )
    .padding()
}
#endif

