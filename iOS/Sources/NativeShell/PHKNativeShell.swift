import SwiftUI
import UIKit

// Native, first-party screen. No injected framework, offset patching, or Zalo session access.
private enum PHKTheme {
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.21)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.57)
    static let blue = Color(red: 0.08, green: 0.45, blue: 0.95)
    static let canvas = Color(red: 0.965, green: 0.972, blue: 0.984)
    static let line = Color(red: 0.90, green: 0.92, blue: 0.95)
}

private enum ShellTab: Int, CaseIterable, Identifiable {
    case messages, contacts, discover, journal, profile
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .messages: return "Tin nhắn"
        case .contacts: return "Danh bạ"
        case .discover: return "Khám phá"
        case .journal: return "Nhật ký"
        case .profile: return "Cá nhân"
        }
    }
    var icon: String {
        switch self {
        case .messages: return "bubble.left.and.bubble.right"
        case .contacts: return "person.crop.circle"
        case .discover: return "square.grid.2x2"
        case .journal: return "rectangle.stack"
        case .profile: return "person.crop.circle.fill"
        }
    }
    var activeIcon: String {
        switch self {
        case .messages: return "bubble.left.and.bubble.right.fill"
        case .contacts: return "person.crop.circle.fill"
        case .discover: return "square.grid.2x2.fill"
        case .journal: return "rectangle.stack.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct PHKNativeShell: View {
    let onOpenSettings: () -> Void
    @State private var selectedTab: ShellTab = .messages
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(ShellTab.allCases) { tab in
                NativePage(tab: tab, onOpenSettings: onOpenSettings)
                    .tag(tab)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(reduceMotion ? nil : .interactiveSpring(response: 0.36, dampingFraction: 0.86),
                   value: selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LiquidTabBar(selection: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 5)
                .padding(.top, 7)
                .background {
                    LinearGradient(colors: [PHKTheme.canvas.opacity(0), PHKTheme.canvas.opacity(0.94)],
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
        .background(PHKTheme.canvas)
        .preferredColorScheme(.light)
    }
}

private struct LiquidTabBar: View {
    @Binding var selection: ShellTab
    @Namespace private var indicator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ShellTab.allCases) { tab in
                Button {
                    choose(tab)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: selection == tab ? tab.activeIcon : tab.icon)
                            .font(.system(size: 19, weight: selection == tab ? .semibold : .regular))
                            .symbolRenderingMode(.hierarchical)
                        Text(tab.label)
                            .font(.system(size: 10, weight: selection == tab ? .semibold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(selection == tab ? PHKTheme.blue : PHKTheme.muted)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(PHKTheme.blue.opacity(0.10))
                                .matchedGeometryEffect(id: "active-liquid-tab", in: indicator)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(6)
        .background(glassBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .strokeBorder(.white.opacity(0.82), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: PHKTheme.ink.opacity(0.09), radius: 15, y: 5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard abs(value.translation.width) > 43,
                          abs(value.translation.width) > abs(value.translation.height) else { return }
                    let next = PHKCore.nextTabIndex(
                        withCurrent: selection.rawValue,
                        count: ShellTab.allCases.count,
                        dragPoints: Double(value.translation.width))
                    guard let tab = ShellTab(rawValue: next) else { return }
                    choose(tab)
                }
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var glassBackground: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: 29))
        } else {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .fill(.regularMaterial)
        }
    }

    private func choose(_ tab: ShellTab) {
        guard tab != selection else { return }
        if !reduceMotion { UISelectionFeedbackGenerator().selectionChanged() }
        withAnimation(reduceMotion ? nil : .interactiveSpring(response: 0.39, dampingFraction: 0.79)) {
            selection = tab
        }
    }
}

private struct ConversationPreview: Identifiable {
    let id: Int
    let name: String
    let initials: String
    let color: Color
    let snippet: String
    let time: String
    let unread: Int
}
private let sampleConversations: [ConversationPreview] = [
    .init(id: 1, name: "Nhóm thiết kế", initials: "TK", color: .indigo,
          snippet: "Bản mẫu giao diện đã sẵn sàng", time: "09:42", unread: 2),
    .init(id: 2, name: "Minh Anh", initials: "MA", color: .teal,
          snippet: "Mình xem lại phần tab nhé", time: "08:55", unread: 0),
    .init(id: 3, name: "Dự án iOS", initials: "iOS", color: .blue,
          snippet: "Kiểm tra trải nghiệm vuốt trang", time: "Hôm qua", unread: 1),
    .init(id: 4, name: "Nhóm bạn", initials: "NB", color: .orange,
          snippet: "Cuối tuần gặp nhau nhé", time: "T2", unread: 0)
]

private struct NativePage: View {
    let tab: ShellTab
    let onOpenSettings: () -> Void
    @State private var query = ""
    @State private var selectedConversation: ConversationPreview?
    @State private var showAction = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if tab == .messages { messagesPage }
                    else if tab == .contacts { contactsPage }
                    else if tab == .discover { discoverPage }
                    else if tab == .journal { journalPage }
                    else { profilePage }
                }
                .padding(.horizontal, 19)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(PHKTheme.canvas)
            .navigationTitle(tab.label)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if tab == .profile { onOpenSettings() }
                        else { showAction = true }
                    } label: {
                        Image(systemName: tab == .profile ? "gearshape" : "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(tab == .profile ? "Cài đặt giao diện" : "Tác vụ thử nghiệm")
                }
            }
            .tint(PHKTheme.blue)
            .sheet(item: $selectedConversation) { message in
                NavigationStack {
                    VStack(spacing: 16) {
                        Avatar(initials: message.initials, color: message.color, size: 64)
                        Text(message.name).font(.title2.weight(.semibold))
                        Text("Bản xem trước hội thoại. Không gửi hoặc đọc tin nhắn Zalo.")
                            .font(.subheadline).foregroundStyle(PHKTheme.muted)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(28)
                    .navigationTitle("Hội thoại minh họa")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) {
                        Button("Đóng") { selectedConversation = nil }
                    } }
                }
                .presentationDetents([.medium])
            }
            .alert("Bản mẫu giao diện", isPresented: $showAction) {
                Button("Đã hiểu", role: .cancel) { }
            } message: {
                Text("Chức năng này chỉ minh họa giao diện, không truy cập tài khoản Zalo.")
            }
        }
    }

    private var messagesPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            previewNotice
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(PHKTheme.muted)
                TextField("Tìm trong hội thoại mẫu", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .font(.subheadline)
            .padding(.horizontal, 15)
            .frame(height: 44)
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            HStack {
                Text("Gần đây").font(.headline)
                Spacer()
                Text("Minh họa").font(.caption).foregroundStyle(PHKTheme.muted)
            }
            VStack(spacing: 0) {
                ForEach(sampleConversations.filter {
                    query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)
                    || $0.snippet.localizedCaseInsensitiveContains(query)
                }) { item in
                    Button { selectedConversation = item } label: {
                        HStack(spacing: 13) {
                            Avatar(initials: item.initials, color: item.color, size: 49)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name).font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(PHKTheme.ink)
                                Text(item.snippet).font(.system(size: 13))
                                    .foregroundStyle(PHKTheme.muted).lineLimit(1)
                            }
                            Spacer(minLength: 2)
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(item.time).font(.caption2).foregroundStyle(PHKTheme.muted)
                                if item.unread > 0 {
                                    Text("\(item.unread)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 19, minHeight: 19)
                                        .background(PHKTheme.blue, in: Circle())
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 76)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if item.id != sampleConversations.last?.id {
                        Divider().padding(.leading, 75).opacity(0.5)
                    }
                }
                if !query.isEmpty && !sampleConversations.contains(where: {
                    $0.name.localizedCaseInsensitiveContains(query) ||
                    $0.snippet.localizedCaseInsensitiveContains(query)
                }) {
                    Text("Không tìm thấy hội thoại mẫu")
                        .font(.subheadline).foregroundStyle(PHKTheme.muted).padding(24)
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var contactsPage: some View {
        VStack(alignment: .leading, spacing: 17) {
            previewNotice
            sectionHeading("Liên hệ", detail: "Danh sách thử nghiệm")
            VStack(spacing: 0) {
                ForEach(sampleConversations.prefix(3)) { item in
                    Button { selectedConversation = item } label: {
                        HStack(spacing: 12) {
                            Avatar(initials: item.initials, color: item.color, size: 46)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(.system(size: 15, weight: .semibold))
                                Text("Liên hệ minh họa").font(.caption).foregroundStyle(PHKTheme.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PHKTheme.muted)
                        }
                        .foregroundStyle(PHKTheme.ink)
                        .padding(15)
                    }
                    if item.id != 3 { Divider().padding(.leading, 72).opacity(0.5) }
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            ActionCard(icon: "person.2.crop.square.stack", title: "Nhóm",
                       subtitle: "Quản lý nhóm trong ứng dụng mẫu", tint: .indigo) {
                showAction = true
            }
        }
    }

    private var discoverPage: some View {
        VStack(alignment: .leading, spacing: 17) {
            previewNotice
            sectionHeading("Tiện ích", detail: "Gọn, dễ sử dụng")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                      spacing: 12) {
                discoverItem("Ảnh", "photo.on.rectangle.angled", .blue)
                discoverItem("Ghi chú", "note.text", .teal)
                discoverItem("Lịch", "calendar", .orange)
                discoverItem("Bộ sưu tập", "square.grid.2x2.fill", .purple)
            }
            sectionHeading("Góc sản phẩm", detail: "PHK")
            VStack(alignment: .leading, spacing: 10) {
                Text("Một giao diện tập trung vào nội dung")
                    .font(.title3.weight(.semibold))
                Text("Phím bấm rõ ràng, hình ảnh vừa khung, hiệu ứng chỉ xuất hiện trên thanh điều hướng.")
                    .font(.subheadline)
                    .foregroundStyle(PHKTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(19)
            .background(.white, in: RoundedRectangle(cornerRadius: 21))
        }
    }

    private func discoverItem(_ title: String, _ icon: String, _ tint: Color) -> some View {
        Button { showAction = true } label: {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(PHKTheme.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 119, alignment: .leading)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 21))
        }
        .buttonStyle(.plain)
    }

    private var journalPage: some View {
        VStack(alignment: .leading, spacing: 17) {
            previewNotice
            sectionHeading("Bảng tin", detail: "Nội dung minh họa")
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Avatar(initials: "PHK", color: PHKTheme.blue, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PHK Studio").font(.subheadline.weight(.semibold))
                        Text("Hôm nay · Nhật ký giao diện")
                            .font(.caption).foregroundStyle(PHKTheme.muted)
                    }
                    Spacer()
                }
                Text("Một thanh tab tốt cần đủ phản hồi khi chạm nhưng không gây phân tâm khi đọc.")
                    .font(.subheadline).foregroundStyle(PHKTheme.ink)
                Image("MenuWallpaper")
                    .resizable().scaledToFill()
                    .frame(height: 155)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .accessibilityLabel("Ảnh nền đã được cắt vừa khung nhật ký")
                HStack(spacing: 20) {
                    Label("12", systemImage: "heart")
                    Label("3", systemImage: "bubble")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
                .font(.subheadline)
                .foregroundStyle(PHKTheme.muted)
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var profilePage: some View {
        VStack(alignment: .leading, spacing: 17) {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geo in
                    Image("MenuWallpaper")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay(LinearGradient(colors: [.clear, .black.opacity(0.5)],
                                                startPoint: .center, endPoint: .bottom))
                }
                .frame(height: 188)
                VStack(alignment: .leading, spacing: 6) {
                    Text("PHK Studio").font(.title2.weight(.bold)).foregroundStyle(.white)
                    Text("Giao diện iOS độc lập")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.88))
                }
                .padding(19)
            }
            .frame(height: 188)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            HStack(spacing: 13) {
                Image("AdminCar")
                    .resizable().scaledToFill()
                    .frame(width: 61, height: 61)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer Phan Anh Khôi").font(.subheadline.weight(.semibold))
                    Text("Bản dùng thử · Không đăng nhập Zalo")
                        .font(.caption).foregroundStyle(PHKTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            ActionCard(icon: "slider.horizontal.3", title: "Bảng điều khiển",
                       subtitle: "Các thiết lập giao diện và mã C++ cũ", tint: PHKTheme.blue,
                       action: onOpenSettings)
            ActionCard(icon: "hand.draw", title: "Điều hướng",
                       subtitle: "Vuốt ngang hoặc kéo trên thanh tab", tint: .teal) {
                showAction = true
            }
            previewNotice
        }
    }

    private var previewNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield").foregroundStyle(PHKTheme.blue)
            Text("Giao diện thử nghiệm — không kết nối Zalo")
                .foregroundStyle(PHKTheme.muted)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(PHKTheme.blue.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 12))
    }

    private func sectionHeading(_ title: String, detail: String) -> some View {
        HStack {
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(PHKTheme.ink)
            Spacer()
            Text(detail).font(.caption).foregroundStyle(PHKTheme.muted)
        }
    }
}

private struct Avatar: View {
    let initials: String
    let color: Color
    let size: CGFloat

    var body: some View {
        Text(initials)
            .font(.system(size: initials.count > 2 ? 12 : 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: Circle())
            .accessibilityHidden(true)
    }
}

private struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 45, height: 45)
                    .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.semibold))
                        .foregroundStyle(PHKTheme.ink)
                    Text(subtitle).font(.caption)
                        .foregroundStyle(PHKTheme.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(PHKTheme.muted)
            }
            .padding(15)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
