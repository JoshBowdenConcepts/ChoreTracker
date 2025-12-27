//
//  SplashView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checklist")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Text("ChoreTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ProgressView()
                    .padding(.top)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}





