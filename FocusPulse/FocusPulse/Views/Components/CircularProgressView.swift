import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let sessionType: SessionType?
    let isRunning: Bool
    
    @State private var animationProgress: Double = 0
    
    private var progressColor: Color {
        sessionType?.color ?? .gray
    }
    
    private var trackColor: Color {
        Color.secondary.opacity(0.2)
    }
    
    private var lineWidth: CGFloat = 8
    private var size: CGFloat = 240
    
    var body: some View {
        ZStack {
            // Background circle (track)
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animationProgress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 0.5), value: animationProgress)
            
            // Pulsing effect when running
            if isRunning {
                Circle()
                    .stroke(
                        progressColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: lineWidth * 2, lineCap: .round)
                    )
                    .frame(width: size + 20, height: size + 20)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationProgress = newValue
            }
        }
        .onAppear {
            animationProgress = progress
        }
    }
    
    // MARK: - Pulse Animation Properties
    @State private var pulseScale: Double = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    private var shouldPulse: Bool {
        isRunning
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        CircularProgressView(
            progress: 0.7,
            sessionType: .work(duration: 1500),
            isRunning: true
        )
        
        CircularProgressView(
            progress: 0.3,
            sessionType: .shortBreak(duration: 300),
            isRunning: false
        )
        
        CircularProgressView(
            progress: 0.9,
            sessionType: .longBreak(duration: 900),
            isRunning: true
        )
    }
    .padding()
} 