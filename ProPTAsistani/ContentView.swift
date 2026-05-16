import SwiftUI
import SwiftData

// MARK: - Tab Item Model
private enum Tab: Int, CaseIterable {
    case today = 0, calendar, clients, settings

    var icon: String {
        switch self {
        case .today:    return "house.fill"
        case .calendar: return "calendar"
        case .clients:  return "person.2.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .today
    @State private var showingNewAppointment = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Active screen
                ZStack {
                    Color(hex: "#141416").ignoresSafeArea()

                    VStack(spacing: 0) {
                        Group {
                            switch selectedTab {
                            case .today:    TodayView(onNavigateToSettings: { selectedTab = .settings })
                            case .calendar: CalendarView()
                            case .clients:  ClientsView()
                            case .settings: SettingsView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if selectedTab == .today || selectedTab == .calendar || selectedTab == .clients {
                            AdBannerContainer()
                        }
                    }
                    .background(Color(hex: "#141416"))
                }

                // Custom tab bar
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showingNewAppointment: $showingNewAppointment,
                    bottomInset: geo.safeAreaInsets.bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .fullScreenCover(isPresented: $showingNewAppointment) {
            NewAppointmentView()
        }
        .onAppear {
            DatabaseManager.shared.setup(context: modelContext)
        }
    }
}

// MARK: - Custom Tab Bar
private struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showingNewAppointment: Bool
    let bottomInset: CGFloat
    @State private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(Color(hex: "#2A2A2D"))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                // Left two tabs
                ForEach([Tab.today, Tab.calendar], id: \.self) { tab in
                    TabItemView(tab: tab, selectedTab: $selectedTab)
                }

                // FAB center
                FABButton(showingNewAppointment: $showingNewAppointment)

                // Müşteriler
                TabItemView(tab: .clients, selectedTab: $selectedTab)

                // Ayarlar — PT Avatar
                AvatarTabItemView(
                    initials: settings.ptInitials,
                    isSelected: selectedTab == .settings
                ) {
                    selectedTab = .settings
                }
            }
            .frame(height: 56)
            .background(Color(hex: "#141416"))
            .padding(.bottom, bottomInset)
        }
        .background(Color(hex: "#141416"))
    }
}

// MARK: - Tab Item View
private struct TabItemView: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    @State private var scale: CGFloat = 1.0

    private var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedTab = tab
            }
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                scale = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .imageScale(isSelected ? .large : .medium)
                    .foregroundStyle(isSelected ? Color(hex: "#F5F4F0") : Color(hex: "#4A4A55"))

                Circle()
                    .fill(isSelected ? Color(hex: "#F5F4F0") : Color.clear)
                    .frame(width: 3, height: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Avatar Tab Item (Ayarlar)
private struct AvatarTabItemView: View {
    let initials: String
    let isSelected: Bool
    let action: () -> Void
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { action() }
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) { scale = 0.85 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.0 }
            }
        } label: {
            VStack(spacing: 4) {
                Text(initials)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(hex: "#141416") : Color(hex: "#A09FA6"))
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color(hex: "#F5F4F0") : Color(hex: "#2C2C2E"))
                    .clipShape(Circle())

                Circle()
                    .fill(isSelected ? Color(hex: "#F5F4F0") : Color.clear)
                    .frame(width: 3, height: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAB Button
private struct FABButton: View {
    @Binding var showingNewAppointment: Bool
    @GestureState private var isPressed = false

    var body: some View {
        Button {
            showingNewAppointment = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: "#141416"))
                .frame(width: 52, height: 52)
                .background(Color(hex: "#F5F4F0"))
                .clipShape(Circle())
                .shadow(color: Color(hex: "#F5F4F0").opacity(0.15), radius: 12, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in state = true }
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Client.self, Appointment.self], inMemory: true)
}
