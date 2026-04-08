import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var userStore: UserStore
    @State private var selectedTab: Tab = .home

    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var goalProgressViewModel = GoalProgressViewModel(userStore: UserStore.shared)

    enum Tab {
        case home, nutrition, goals, profile
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                        .environmentObject(userStore)
                case .nutrition:
                    NutritionView(viewModel: nutritionViewModel)
                        .environmentObject(userStore)
                case .goals:
                    GoalProgressView(viewModel: goalProgressViewModel)
                        .environmentObject(userStore)
                case .profile:
                    ProfileView()
                        .environmentObject(userStore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            VStack(spacing: 0) {
                Divider()
                    .background(AltoTheme.border)
                HStack(spacing: 0) {
                    tabButton(tab: .home, icon: "house", label: "Home")
                    tabButton(tab: .nutrition, icon: "leaf", label: "Nutrition")
                    tabButton(tab: .goals, icon: "flag", label: "Goals")
                    tabButton(tab: .profile, icon: "person", label: "Profile")
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .background(AltoTheme.card)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(AltoTheme.border),
                    alignment: .top
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(AltoTheme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func tabButton(tab: Tab, icon: String, label: String) -> some View {
        let isActive = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: isActive ? .semibold : .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isActive ? AltoTheme.primary : AltoTheme.textSecondary)
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? AltoTheme.primary : AltoTheme.textSecondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
