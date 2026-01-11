//
//  BrowserView.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import SwiftUI

struct BrowserView: View {
    let platform: Platform
    let coordinator: WebViewCoordinator
    
    @State private var urlText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Browser Controls
            browserControls
            
            Divider()
                .background(Color.appBorder)
            
            // WebView
            WebView(url: platform.url, coordinator: coordinator)
                .background(Color.appSecondary)
        }
        .background(Color.appBackground)
        .onChange(of: coordinator.currentURL) { newURL in
            urlText = newURL?.absoluteString ?? platform.url.absoluteString
        }
        .onAppear {
            urlText = platform.url.absoluteString
        }
    }
    
    private var browserControls: some View {
        HStack(spacing: 8) {
            // Navigation Buttons
            HStack(spacing: 4) {
                BrowserButton(
                    icon: "chevron.left",
                    isEnabled: coordinator.canGoBack
                ) {
                    coordinator.goBack()
                }
                
                BrowserButton(
                    icon: "chevron.right",
                    isEnabled: coordinator.canGoForward
                ) {
                    coordinator.goForward()
                }
                
                BrowserButton(
                    icon: coordinator.isLoading ? "xmark" : "arrow.clockwise",
                    isEnabled: true
                ) {
                    coordinator.reload()
                }
                
                BrowserButton(
                    icon: "house",
                    isEnabled: true
                ) {
                    coordinator.goHome(url: platform.url)
                }
            }
            
            // URL Bar
            HStack {
                if coordinator.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextMuted)
                }
                
                TextField("URL", text: $urlText)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appText)
                    .onSubmit {
                        var urlString = urlText
                        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                            urlString = "https://" + urlString
                        }
                        coordinator.loadURL(urlString)
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.appSecondary)
            .cornerRadius(AppDimensions.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .padding(AppDimensions.padding)
        .background(Color.appBackground)
    }
}

// MARK: - Browser Button
struct BrowserButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isEnabled ? Color.appText : Color.appTextMuted.opacity(0.5))
                .frame(width: 28, height: 28)
                .background(
                    isHovered && isEnabled ?
                    Color.appSecondary :
                        Color.clear
                )
                .cornerRadius(AppDimensions.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.borderRadius)
                        .stroke(
                            isHovered && isEnabled ? Color.appBorderHover : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appSuccess)
            .cornerRadius(AppDimensions.borderRadius)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 40)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, duration: Double = 1.5) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, duration: duration))
    }
}
