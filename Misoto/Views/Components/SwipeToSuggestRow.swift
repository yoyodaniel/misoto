//
//  SwipeToSuggestRow.swift
//  Misoto
//
//  Swipe left to reveal “Suggest” without a permanent trailing control (works inside ScrollView).
//

import SwiftUI

// MARK: - SwipeToSuggestRow

struct SwipeToSuggestRow<Content: View>: View {
    let onSuggest: () -> Void
    private let content: () -> Content
    
    init(onSuggest: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onSuggest = onSuggest
        self.content = content
    }
    
    @State private var offset: CGFloat = 0
    @State private var anchorOffset: CGFloat = 0
    @State private var horizontalDragActive = false
    
    private let actionWidth: CGFloat = 92
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: {
                HapticFeedback.importantAction()
                onSuggest()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    offset = 0
                }
            }) {
                Text(LocalizedString("Suggest", comment: "Swipe-revealed suggest short label"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)
            .background(Color.orange)
            
            HStack(spacing: 0) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .offset(x: offset)
            .simultaneousGesture(horizontalSwipeGesture)
        }
        .clipped()
        .contextMenu {
            Button {
                HapticFeedback.buttonTap()
                onSuggest()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    offset = 0
                }
            } label: {
                Text(LocalizedString("Suggest a change", comment: "Recipe suggest menu"))
            }
        }
    }
    
    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                
                if !horizontalDragActive {
                    if abs(dx) < 10 && abs(dy) < 10 { return }
                    if abs(dy) >= abs(dx) * 0.85 {
                        return
                    }
                    horizontalDragActive = true
                    anchorOffset = offset
                }
                guard horizontalDragActive else { return }
                let next = anchorOffset + dx
                offset = min(0, max(-actionWidth, next))
            }
            .onEnded { value in
                defer { horizontalDragActive = false }
                guard horizontalDragActive else { return }
                
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dy) >= abs(dx) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        offset = anchorOffset
                    }
                    return
                }
                
                let predictedExtra = value.predictedEndTranslation.width - value.translation.width
                let projected = offset + predictedExtra
                
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    if offset < -actionWidth * 0.33 || projected < -actionWidth * 0.5 {
                        offset = -actionWidth
                    } else {
                        offset = 0
                    }
                }
            }
    }
}

#if DEBUG
#Preview {
    SwipeToSuggestRow(onSuggest: {}) {
        Text("Sample ingredient line that can wrap to two lines when needed.")
            .padding(.vertical, 8)
    }
    .padding(.horizontal)
}
#endif
