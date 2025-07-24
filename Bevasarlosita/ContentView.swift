//
//  ContentView.swift
//  Bevasarlosita
//
//  Created by Márk Gavallér on 2025. 07. 14..
//

struct Tetel: Identifiable, Codable, Equatable {
    let id: UUID
    let nev: String
    var kesz: Bool
    let kategoria: String
    let letrehozva: Date

    init(id: UUID = UUID(), nev: String, kesz: Bool = false, kategoria: String, letrehozva: Date = Date()) {
        self.id = id
        self.nev = nev
        self.kategoria = kategoria
        self.kesz = kesz
        self.letrehozva = letrehozva
    }
}

import SwiftUI

struct Kategoria: Identifiable, Codable, Equatable {
    let id: UUID
    var nev: String
    var ikon: String

    init(id: UUID = UUID(), nev: String, ikon: String) {
        self.id = id
        self.nev = nev
        self.ikon = ikon
    }
}

struct ContentView: View {
    @State private var ujTetel = ""
    @State private var tetelek: [Tetel] = []
    @State var selectedKategoria: Kategoria
    @State private var keresettSzoveg = ""
    @State private var szerkesztesAlatt: Tetel? = nil
    @FocusState private var szovegMezoAktiv: Bool
    @State private var showSettings = false
    
    let mentesiKulcs = "BevasarlolistaAdatok"
    @AppStorage("kategoriak") private var kategoriakData: Data = Data()
    
    let alapKategoriak: [Kategoria] = [
        Kategoria(nev: "Élelmiszer", ikon: "cart"),
        Kategoria(nev: "Háztartás", ikon: "house"),
        Kategoria(nev: "Egyéb", ikon: "ellipsis.circle")
    ]

    var kategoriak: [Kategoria] {
        if let decoded = try? JSONDecoder().decode([Kategoria].self, from: kategoriakData), !decoded.isEmpty {
            return decoded
        } else {
            return alapKategoriak
        }
    }
    
    init(selectedKategoria: Kategoria = Kategoria(nev: "Élelmiszer", ikon: "cart")) {
        _selectedKategoria = State(initialValue: selectedKategoria)
    }
    
    func mentes() {
        if let adatok = try? JSONEncoder().encode(tetelek) {
            UserDefaults.standard.set(adatok, forKey: mentesiKulcs)
        }
    }

    func betoltes() {
        if let adatok = UserDefaults.standard.data(forKey: mentesiKulcs),
           let betoltott = try? JSONDecoder().decode([Tetel].self, from: adatok) {
            tetelek = betoltott
        }
    }

    var body: some View {
        NavigationView {
            NavigationStack {
                VStack {
                    TextField("🔍 Keresés...", text: $keresettSzoveg)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(kategoriak) { kat in
                                Button(action: {
                                    selectedKategoria = kat
                                }) {
                                    Label(kat.nev, systemImage: kat.ikon)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedKategoria.id == kat.id ? Color.accentColor : Color.gray.opacity(0.3))
                                        .foregroundColor(selectedKategoria.id == kat.id ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    HStack {
                        TextField("Új tétel", text: $ujTetel)
                            .textFieldStyle(.roundedBorder)
                            .focused($szovegMezoAktiv)
                            .onSubmit {
                                guard !ujTetel.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                tetelek.append(Tetel(nev: ujTetel, kategoria: selectedKategoria.nev))
                                ujTetel = ""
                            }
                        Button("➕") {
                            guard !ujTetel.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            tetelek.append(Tetel(nev: ujTetel, kategoria: selectedKategoria.nev))
                            ujTetel = ""
                        }
                    }
                    .padding()
                    let szurtTetelek = tetelek.filter {
                        $0.kategoria == selectedKategoria.nev && (keresettSzoveg.isEmpty || $0.nev.localizedCaseInsensitiveContains(keresettSzoveg))
                    }
                    List {
                        ForEach(szurtTetelek) { tetel in
                            HStack {
                                Image(systemName: tetel.kesz ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tetel.kesz ? .green : .gray)
                                    .onTapGesture {
                                        if let eredetiIndex = tetelek.firstIndex(where: { $0.id == tetel.id }) {
                                            tetelek[eredetiIndex].kesz.toggle()
                                        }
                                    }

                                VStack(alignment: .leading) {
                                    Text(tetel.nev)
                                        .strikethrough(tetel.kesz)
                                        .foregroundColor(tetel.kesz ? .gray : .primary)

                                    Text(tetel.letrehozva, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onLongPressGesture {
                                ujTetel = tetel.nev
                                if let kat = kategoriak.first(where: { $0.nev == tetel.kategoria }) {
                                    selectedKategoria = kat
                                }
                                tetelek.removeAll { $0.id == tetel.id }
                                szovegMezoAktiv = true
                            }
                        }
                        .onDelete { offsets in
                            let kategoriabeliTetelek = tetelek.enumerated().filter { $0.element.kategoria == selectedKategoria.nev }
                            let torlendoIndexek = offsets.compactMap { offsetsIndex in
                                kategoriabeliTetelek.indices.contains(offsetsIndex) ? kategoriabeliTetelek[offsetsIndex].offset : nil
                            }
                            tetelek.removeAll { tetel in
                                torlendoIndexek.contains(where: { $0 == tetelek.firstIndex(where: { $0.id == tetel.id }) })
                            }
                        }
                    }
                }
                .navigationTitle("Bevásárlólista")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView(tetelek: $tetelek)) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .onAppear {
                betoltes()
            }
            .onChange(of: tetelek) { _, _ in
                mentes()
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @Binding var tetelek: [Tetel]
    @AppStorage("kategoriak") private var kategoriakData: Data = Data()
    @State private var szerkeszthetoKategoriak: [Kategoria] = []
    let alapKategoriak: [Kategoria] = [
        Kategoria(nev: "Élelmiszer", ikon: "cart"),
        Kategoria(nev: "Háztartás", ikon: "house"),
        Kategoria(nev: "Egyéb", ikon: "ellipsis.circle")
    ]
    
    var body: some View {
        // Ikon opciók helyi konstans
        let elerhetoIkonok = ["cart", "house", "ellipsis.circle", "tshirt", "fork.knife", "leaf", "bolt", "gift", "bag", "bookmark", "star"]
        Form {
            Section(header: Text("Megjelenés")) {
                Toggle("Sötét mód", isOn: $darkMode)
            }
            Section(header: Text("Kategóriák")) {
                ForEach(szerkeszthetoKategoriak.indices, id: \.self) { idx in
                    HStack {
                        TextField("Kategória neve", text: Binding(
                            get: { szerkeszthetoKategoriak[idx].nev },
                            set: { ujErtek in
                                szerkeszthetoKategoriak[idx].nev = ujErtek
                            }
                        ))
                        .disableAutocorrection(true)
                        Menu {
                            ForEach(elerhetoIkonok, id: \.self) { ikon in
                                Button {
                                    szerkeszthetoKategoriak[idx].ikon = ikon
                                } label: {
                                    Label(ikon, systemImage: ikon)
                                }
                            }
                        } label: {
                            Image(systemName: szerkeszthetoKategoriak[idx].ikon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            szerkeszthetoKategoriak.remove(at: idx)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                Button {
                    szerkeszthetoKategoriak.append(Kategoria(nev: "", ikon: "questionmark.circle"))
                } label: {
                    Label("Új kategória", systemImage: "plus.circle")
                }
            }
            Section {
                Button(role: .destructive) {
                    tetelek.removeAll()
                } label: {
                    Text("Összes tétel törlése")
                }
            }
        }
        .navigationTitle("Beállítások")
        .onAppear {
            if let decoded = try? JSONDecoder().decode([Kategoria].self, from: kategoriakData), !decoded.isEmpty {
                szerkeszthetoKategoriak = decoded
            } else {
                szerkeszthetoKategoriak = alapKategoriak
            }
        }
        .onChange(of: szerkeszthetoKategoriak) { _, ujLista in
            if let encoded = try? JSONEncoder().encode(ujLista) {
                kategoriakData = encoded
            }
        }
    }
}

#Preview {
    ContentView(selectedKategoria: Kategoria(nev: "Élelmiszer", ikon: "cart"))
}
