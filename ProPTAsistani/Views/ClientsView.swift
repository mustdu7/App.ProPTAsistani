import SwiftUI

struct ClientsView: View {
    @State private var db = DatabaseManager.shared

    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Tümü"
    @State private var selectedClient: Client? = nil

    private let filters = ["Tümü", "Aktif", "Pasif", "Paketi Bitenler"]

    private var filteredClients: [Client] {
        let searched = searchText.isEmpty
            ? db.clients
            : db.clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        switch selectedFilter {
        case "Aktif":           return searched.filter { $0.isActive }
        case "Pasif":           return searched.filter { !$0.isActive }
        case "Paketi Bitenler": return searched.filter { $0.remainingSessions <= 1 }
        default:                return searched
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#141416").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Müşteriler")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color(hex: "#F5F4F0"))
                        Text("\(db.clients.filter { $0.isActive }.count) aktif müşteri")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#A09FA6"))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Rectangle().fill(Color(hex: "#2A2A2D")).frame(height: 0.5)

                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: Arama
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14)).foregroundStyle(Color(hex: "#A09FA6"))
                            TextField("Müşteri ara...", text: $searchText)
                                .font(.system(size: 15)).foregroundStyle(Color(hex: "#F5F4F0"))
                                .tint(Color(hex: "#F5F4F0"))
                        }
                        .padding(10)
                        .background(Color(hex: "#1E1E22"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
                        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)

                        // MARK: Filtreler
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters, id: \.self) { filter in
                                    Button { selectedFilter = filter } label: {
                                        Text(filter)
                                            .font(.system(size: 12, weight: selectedFilter == filter ? .semibold : .regular))
                                            .foregroundStyle(selectedFilter == filter ? Color(hex: "#141416") : Color(hex: "#A09FA6"))
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(selectedFilter == filter ? Color(hex: "#F5F4F0") : Color(hex: "#1E1E22"))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().strokeBorder(selectedFilter == filter ? Color.clear : Color(hex: "#2A2A2D"), lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 8)

                        // MARK: Liste
                        if filteredClients.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "person.slash").font(.system(size: 36)).foregroundStyle(Color(hex: "#2C2C2E"))
                                Text("Müşteri bulunamadı").font(.system(size: 14)).foregroundStyle(Color(hex: "#A09FA6"))
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredClients) { client in
                                    Button { selectedClient = client } label: {
                                        ClientRowView(client: client)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            db.toggleClientActive(client)
                                        } label: {
                                            Label(client.isActive ? "Pasife Al" : "Aktife Al",
                                                  systemImage: client.isActive ? "pause.circle" : "play.circle")
                                        }
                                        .tint(Color(hex: "#F0A500"))
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            db.deleteClient(client)
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }
                                        .tint(Color(hex: "#E05C5C"))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .scrollBounceBehavior(.always)
            }
        }
        .sheet(item: $selectedClient) { client in
            ClientDetailView(client: client)
        }
        .alert("Hata", isPresented: Binding(
            get: { db.lastError != nil },
            set: { if !$0 { db.lastError = nil } }
        )) {
            Button("Tamam") { db.lastError = nil }
        } message: {
            Text(db.lastError ?? "")
        }
        .onAppear {
            db.fetchClients()
        }
    }
}

// MARK: - Client Row View
private struct ClientRowView: View {
    let client: Client

    private var isDevamli: Bool { client.totalSessions == 0 }

    private var totalCount: Int {
        isDevamli ? client.appointments.count : client.totalSessions
    }

    private var completedCount: Int {
        isDevamli
            ? client.appointments.filter { $0.isCompleted }.count
            : client.totalSessions - client.remainingSessions
    }

    private var progressColor: Color {
        if isDevamli { return Color(hex: "#5C6BC0") }
        if client.remainingSessions == 0 { return Color(hex: "#E05C5C") }
        if client.remainingSessions <= 2 { return Color(hex: "#F0A500") }
        return Color(hex: "#5C6BC0")
    }

    private var progress: CGFloat {
        totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(client.initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(client.isActive ? Color(hex: "#F5F4F0") : Color(hex: "#4A4A55"))
                    .frame(width: 44, height: 44)
                    .background(client.isActive ? Color(hex: "#2C2C2E") : Color(hex: "#1C1C1E"))
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(client.isActive ? Color(hex: "#3A3A3C") : Color(hex: "#2A2A2D"), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 3) {
                    Text(client.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(client.isActive ? Color(hex: "#F5F4F0") : Color(hex: "#4A4A55"))
                    Text(client.phone.isEmpty ? "Telefon eklenmedi" : client.phone)
                        .font(.system(size: 12))
                        .foregroundStyle(client.phone.isEmpty ? Color(hex: "#3A3A3C") : Color(hex: "#A09FA6"))
                }

                Spacer()

                Text(client.isActive ? "Aktif" : "Pasif")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(client.isActive ? Color(hex: "#4CAF50") : Color(hex: "#4A4A55"))
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(client.isActive ? Color(hex: "#1A2A1A") : Color(hex: "#2A2A2A"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Rectangle().fill(Color(hex: "#2A2A2D")).frame(height: 0.5).padding(.vertical, 10)

            VStack(spacing: 6) {
                HStack {
                    Text(client.packageName).font(.system(size: 12)).foregroundStyle(Color(hex: "#A09FA6"))
                    Spacer()
                    Text("\(completedCount)/\(totalCount) ders").font(.system(size: 12)).foregroundStyle(Color(hex: "#F5F4F0"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#2C2C2E")).frame(height: 3)
                        RoundedRectangle(cornerRadius: 2).fill(progressColor).frame(width: geo.size.width * progress, height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(14)
        .background(Color(hex: "#1E1E22"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#2A2A2D"), lineWidth: 0.5))
    }
}

#Preview {
    ClientsView()
        .modelContainer(for: [Client.self, Appointment.self], inMemory: true)
}
