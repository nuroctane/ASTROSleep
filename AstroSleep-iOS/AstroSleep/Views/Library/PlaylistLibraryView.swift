import SwiftUI

// MARK: - Playlist Library View
struct PlaylistLibraryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var revenueCat: RevenueCatService
    
    @State private var combos: [Combo] = []
    @State private var showingDeleteConfirm = false
    @State private var comboToDelete: Combo?
    @State private var selectedCombo: Combo?
    @State private var showingComboDetail = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(combos) { combo in
                    PlaylistRow(combo: combo)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if combo.isReadOnly {
                                // Show paywall for locked combos
                                appState.paywallTrigger = "edit_locked_combo"
                                appState.showPaywall = true
                            } else {
                                selectedCombo = combo
                                showingComboDetail = true
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !combo.isReadOnly {
                                Button(role: .destructive) {
                                    comboToDelete = combo
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
                
                if combos.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No saved combos yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Create your first combo from the Tonight screen or Sound Library.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                
                // Tier limit info
                if revenueCat.currentTier.maxPlaylists != Int.max {
                    Section {
                        HStack {
                            Text("\(combos.count)/\(revenueCat.currentTier.maxPlaylists) saved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if combos.count >= revenueCat.currentTier.maxPlaylists {
                                Button("Upgrade") {
                                    appState.paywallTrigger = "playlist_limit"
                                    appState.showPaywall = true
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Library")
            .refreshable {
                loadCombos()
            }
            .onAppear {
                loadCombos()
            }
            .sheet(isPresented: $showingComboDetail) {
                if let combo = selectedCombo {
                    ComboBuilderView(existingCombo: combo)
                }
            }
            .alert("Delete Combo?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let combo = comboToDelete {
                        deleteCombo(combo)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This combo will be permanently deleted.")
            }
        }
    }
    
    private func loadCombos() {
        combos = StorageService.shared.loadCombos()
    }
    
    private func deleteCombo(_ combo: Combo) {
        do {
            try StorageService.shared.deleteCombo(id: combo.id)
            loadCombos()
        } catch {
            appState.errorMessage = "Failed to delete combo"
        }
    }
}

// MARK: - Playlist Row

struct PlaylistRow: View {
    let combo: Combo
    
    var body: some View {
        HStack(spacing: 12) {
            // Element indicator
            VStack(spacing: 2) {
                ForEach(combo.dominantElements.prefix(2), id: \.self) { element in
                    Circle()
                        .fill(element.color)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(combo.name)
                        .font(.headline)
                    
                    if combo.isReadOnly {
                        Text("Read-only")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("\(combo.layers.count) layer\(combo.layers.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastPlayed = combo.lastPlayedAt {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(timeAgo(from: lastPlayed))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
