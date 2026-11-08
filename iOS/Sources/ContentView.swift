import SwiftUI

private enum Palette {
    static let canvas = Color(red: 0.045, green: 0.063, blue: 0.10)
    static let accent = Color(red: 0.26, green: 0.83, blue: 0.96)
    static let surface = Color.white.opacity(0.105)
    static let secondary = Color.white.opacity(0.68)
}

enum PanelSection: String, CaseIterable, Identifiable {
    case messages = "Tin nhắn", appearance = "Giao diện", groups = "Nhóm", tools = "Công cụ"
    var id: Self { self }
    var icon: String {
        switch self {
        case .messages: return "message.fill"
        case .appearance: return "paintbrush.pointed.fill"
        case .groups: return "person.2.fill"
        case .tools: return "slider.horizontal.3"
        }
    }
}

struct ContentView: View {
    @State private var menuVisible = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                wallpaper
                VStack(spacing: 14) {
                    Spacer()
                    Text("DEVELOPER PHAN ANH KHÔI")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Chạm bốn ngón tay để mở bảng điều khiển")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 46)
                if menuVisible {
                    Color.black.opacity(0.42)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.spring(response: 0.35)) { menuVisible = false } }
                    PanelView(close: { withAnimation(.spring(response: 0.35)) { menuVisible = false } })
                        .frame(maxWidth: 520)
                        .frame(height: min(geo.size.height * 0.84, 760))
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.canvas)
            .background(FourFingerTapCapture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) { menuVisible.toggle() }
            }.frame(width: 1, height: 1))
        }
        .preferredColorScheme(.dark)
    }
    private var wallpaper: some View {
        GeometryReader { geo in
            Group {
                if UIImage(named: "MenuWallpaper") != nil {
                    Image("MenuWallpaper").resizable().scaledToFill()
                } else {
                    LinearGradient(colors: [.black, Palette.canvas, .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .overlay(LinearGradient(colors: [.black.opacity(0.18), .clear, .black.opacity(0.60)], startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
        }
    }
}

private struct PanelView: View {
    let close: () -> Void
    @State private var section = PanelSection.messages
    @AppStorage("phk.antiUndo") private var antiUndo = false
    @AppStorage("phk.hideSeen") private var hideSeen = false
    @AppStorage("phk.hideTyping") private var hideTyping = false
    @AppStorage("phk.lowMotion") private var lowMotion = true
    @AppStorage("phk.useWallpaper") private var useWallpaper = true
    @AppStorage("phk.compact") private var compact = false
    @State private var ttlValue = "30"
    @State private var ttlUnit = 0
    @State private var normalizedTTL = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(.white.opacity(0.09)).frame(height: 1)
            sectionPicker.padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    switch section {
                    case .messages: messageSettings
                    case .appearance: appearanceSettings
                    case .groups: groupSettings
                    case .tools: toolSettings
                    }
                    HStack {
                        Text("MẪU GIAO DIỆN • v\(PHKCore.coreVersion())")
                        Spacer()
                        Text("iOS 16+")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.secondary)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 28).fill(Palette.canvas.opacity(0.88)))
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Palette.accent.opacity(0.42), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 28, y: 15)
    }
    private var header: some View {
        HStack(spacing: 12) {
            Group {
                if UIImage(named: "AdminCar") != nil {
                    Image("AdminCar").resizable().scaledToFill()
                } else {
                    ZStack { Circle().fill(Palette.accent.opacity(0.18)); Text("PK").font(.system(size: 18, weight: .black)).foregroundStyle(Palette.accent) }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Palette.accent.opacity(0.6), lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text("Developer Phan Anh Khôi")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("BẢNG ĐIỀU KHIỂN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(Palette.accent)
                }
            }
            Spacer(minLength: 4)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 35, height: 35)
                    .foregroundStyle(.white)
                    .background(.white.opacity(0.10), in: Circle())
            }
            .accessibilityLabel("Đóng bảng điều khiển")
        }
        .padding(16)
    }
    private var sectionPicker: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(PanelSection.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { section = item }
                } label: {
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(section == item ? Palette.canvas : .white.opacity(0.82))
                        .background(section == item ? Palette.accent : Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    private var messageSettings: some View {
        VStack(spacing: 10) {
            sectionTitle("TÙY CHỌN TIN NHẮN", symbol: "message.badge")
            settingToggle("Chống thu hồi", detail: "Mô phỏng cấu hình giữ tin nhắn", isOn: $antiUndo)
            settingToggle("Ẩn đã xem", detail: "Trạng thái giao diện thử nghiệm", isOn: $hideSeen)
            settingToggle("Ẩn đang nhập", detail: "Trạng thái giao diện thử nghiệm", isOn: $hideTyping)
            ttlCard
        }
    }
    private var appearanceSettings: some View {
        VStack(spacing: 10) {
            sectionTitle("GIAO DIỆN CÁ NHÂN", symbol: "paintpalette")
            settingToggle("Nền ảnh toàn màn hình", detail: "Ảnh được đóng gói trong ứng dụng", isOn: $useWallpaper)
            settingToggle("Bố cục tối giản", detail: "Giảm thông tin không cần thiết", isOn: $compact)
            settingToggle("Giảm chuyển động", detail: "Ưu tiên hoạt ảnh nhẹ", isOn: $lowMotion)
            infoCard("Màu chủ đạo", value: "Ice cyan / graphite", symbol: "circle.hexagongrid")
        }
    }
    private var groupSettings: some View {
        VStack(spacing: 10) {
            sectionTitle("TỔ CHỨC NHÓM", symbol: "person.2")
            infoCard("Nhóm yêu thích", value: "Chưa kết nối", symbol: "person.2.fill")
            infoCard("Phân loại nhãn", value: "Giao diện minh họa", symbol: "tag")
            infoCard("Lọc thông báo", value: "Chưa triển khai", symbol: "bell.badge")
        }
    }
    private var toolSettings: some View {
        VStack(spacing: 10) {
            sectionTitle("CÔNG CỤ & BẢO MẬT", symbol: "wrench.and.screwdriver")
            infoCard("Mở menu", value: "Chạm bốn ngón tay", symbol: "hand.tap")
            infoCard("Thông tin phiên", value: "Không truy cập cookie", symbol: "lock.shield")
            infoCard("Chế độ hoạt động", value: "Bản xem trước", symbol: "checkmark.shield")
            Text("Không nhúng token, không lưu mật khẩu và không can thiệp vào ứng dụng bên thứ ba.")
                .font(.footnote).foregroundStyle(Palette.secondary).padding(12)
        }
    }
    private var ttlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Thời gian TTL (mô phỏng)", systemImage: "timer")
                .font(.system(size: 13, weight: .semibold))
            Picker("Đơn vị", selection: $ttlUnit) {
                Text("Giây").tag(0)
                Text("Giờ").tag(1)
                Text("Ngày").tag(2)
            }
            .pickerStyle(.segmented)
            HStack {
                TextField("Nhập số", text: $ttlValue)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 9))
                Button("Lưu") {
                    normalizedTTL = PHKCore.normalizeTTL(withValue: Int(ttlValue) ?? 0, unit: ttlUnit)
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
            }
            Text("Giá trị quy đổi: \(normalizedTTL) giây · Giới hạn 30 ngày")
                .font(.caption2).foregroundStyle(Palette.secondary)
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 17))
    }
    private func settingToggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 11)).foregroundStyle(Palette.secondary)
            }
        }
        .tint(Palette.accent)
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16))
    }
    private func infoCard(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).frame(width: 22).foregroundStyle(Palette.accent)
            Text(title).font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 4)
            Text(value).font(.caption).foregroundStyle(Palette.secondary)
        }
        .padding(14).background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
    }
    private func sectionTitle(_ text: String, symbol: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
            Text(text).tracking(1.5)
            Spacer()
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Palette.accent)
        .padding(.top, 7)
    }
}
