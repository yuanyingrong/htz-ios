import ComposableArchitecture
import DesignSystem
import NetworkKit
import SwiftUI

@Reducer
public struct UserInfoFeature {
    @ObservableState
    public struct State: Equatable {
        public var profile: UserProfile
        public var editing: Field?
        public var draft = ""
        public var isSexPickerPresented = false
        public var isRegionPickerPresented = false
        public var isUnbindConfirmPresented = false
        public var toast: String?

        public init(profile: UserProfile) {
            self.profile = profile
        }

        public enum Field: Equatable {
            case nickname, signature
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case edit(State.Field)
        case commitEdit
        case cancelEdit
        case setSex(Int)
        case setRegion(province: String, city: String)
        case phoneTapped
        case unbindConfirmed
        case saved(UserProfile)
        case saveFailed(UserProfile)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case profileChanged(UserProfile)
            case bindPhone(String)
        }
    }

    @Dependency(\.library) var library

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding, .delegate:
                return .none

            case let .edit(field):
                state.editing = field
                state.draft = field == .nickname ? state.profile.nickname : state.profile.signature
                return .none

            case .cancelEdit:
                state.editing = nil
                return .none

            case .commitEdit:
                guard let field = state.editing else { return .none }
                state.editing = nil
                let value = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
                var profile = state.profile
                switch field {
                case .nickname:
                    guard !value.isEmpty else {
                        state.toast = "昵称不能为空"
                        return .none
                    }
                    profile.nickname = String(value.prefix(32))
                case .signature:
                    profile.signature = String(value.prefix(60))
                }
                return save(&state, profile)

            case let .setSex(sex):
                var profile = state.profile
                profile.sex = sex
                return save(&state, profile)

            case let .setRegion(province, city):
                var profile = state.profile
                profile.province = province
                profile.city = city
                return save(&state, profile)

            case .phoneTapped:
                if state.profile.mobile.isEmpty {
                    return .send(.delegate(.bindPhone("")))
                }
                state.isUnbindConfirmPresented = true
                return .none

            case .unbindConfirmed:
                var profile = state.profile
                profile.mobile = ""
                return save(&state, profile)

            case let .saved(profile):
                state.toast = "已修改"
                return .send(.delegate(.profileChanged(profile)))

            case let .saveFailed(previous):
                state.profile = previous
                state.toast = "修改失败"
                return .none
            }
        }
    }

    private func save(_ state: inout State, _ profile: UserProfile) -> Effect<Action> {
        let previous = state.profile
        state.profile = profile
        return .run { send in
            do {
                try await library.updateProfile(profile)
                await send(.saved(profile))
            } catch {
                await send(.saveFailed(previous))
            }
        }
    }
}

struct UserInfoView: View {
    @Perception.Bindable var store: StoreOf<UserInfoFeature>

    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("头像")
                            .font(.system(size: 15))
                            .foregroundColor(HTZColor.title)
                        Spacer()
                        Avatar(url: store.profile.avatar, size: 56)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 76)
                    .background(HTZColor.card)
                    HTZDivider()
                    row("昵称", store.profile.nickname) { store.send(.edit(.nickname)) }
                    HTZDivider()
                    row("性别", store.profile.sexText) { store.send(.binding(.set(\.isSexPickerPresented, true))) }
                    HTZDivider()
                    row("地区", store.profile.region.isEmpty ? "未设置" : store.profile.region) {
                        store.send(.binding(.set(\.isRegionPickerPresented, true)))
                    }
                    HTZDivider()
                    row("手机号", store.profile.mobile.isEmpty ? "未绑定" : PhoneNumber.masked(store.profile.mobile)) {
                        store.send(.phoneTapped)
                    }
                    HTZDivider()
                    row("签名", store.profile.signature.isEmpty ? "编辑个性签名" : store.profile.signature) {
                        store.send(.edit(.signature))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(12)
            }
            .htzPage("个人信息")
            .htzToast($store.toast)
            .alert(
                store.editing == .nickname ? "修改昵称" : "修改签名",
                isPresented: Binding(get: { store.editing != nil }, set: { if !$0 { store.send(.cancelEdit) } })
            ) {
                TextField(store.editing == .nickname ? "请输入昵称" : "请输入签名", text: $store.draft)
                Button("取消", role: .cancel) { store.send(.cancelEdit) }
                Button("确定") { store.send(.commitEdit) }
            }
            .confirmationDialog("选择性别", isPresented: $store.isSexPickerPresented) {
                Button("男") { store.send(.setSex(1)) }
                Button("女") { store.send(.setSex(2)) }
            }
            .confirmationDialog("确定解除手机号绑定？", isPresented: $store.isUnbindConfirmPresented, titleVisibility: .visible) {
                Button("更换手机号") { store.send(.delegate(.bindPhone(store.profile.mobile))) }
                Button("解除绑定", role: .destructive) { store.send(.unbindConfirmed) }
            }
            .sheet(isPresented: $store.isRegionPickerPresented) {
                RegionPicker(province: store.profile.province, city: store.profile.city) { province, city in
                    store.send(.setRegion(province: province, city: city))
                }
                .presentationDetents([.height(320)])
            }
        }
    }

    private func row(_ title: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HTZMenuRow(title: title, value: value)
        }
        .buttonStyle(.plain)
    }
}

struct Avatar: View {
    let url: String
    let size: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if case let .success(image) = phase {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(HTZColor.hint.opacity(0.5))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct RegionPicker: View {
    let onConfirm: (String, String) -> Void
    @State private var province: String
    @State private var city: String
    @Environment(\.dismiss) private var dismiss

    init(province: String, city: String, onConfirm: @escaping (String, String) -> Void) {
        let initialProvince = Region.provinces.contains(province) ? province : Region.provinces[0]
        _province = State(initialValue: initialProvince)
        let cities = Region.cities(initialProvince)
        _city = State(initialValue: cities.contains(city) ? city : cities[0])
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("取消") { dismiss() }
                Spacer()
                Text("选择地区").font(.system(size: 16, weight: .medium))
                Spacer()
                Button("确定") {
                    onConfirm(province, city)
                    dismiss()
                }
            }
            .foregroundColor(HTZColor.title)
            .padding(16)
            HStack(spacing: 0) {
                Picker("省份", selection: $province) {
                    ForEach(Region.provinces, id: \.self) { Text($0).tag($0) }
                }
                Picker("城市", selection: $city) {
                    ForEach(Region.cities(province), id: \.self) { Text($0).tag($0) }
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: province) { newValue in
                city = Region.cities(newValue).first ?? ""
            }
        }
    }
}

enum Region {
    static let data: [(String, [String])] = [
        ("北京", ["北京"]),
        ("天津", ["天津"]),
        ("河北", ["石家庄", "唐山", "秦皇岛", "邯郸", "邢台", "保定", "张家口", "承德", "沧州", "廊坊", "衡水"]),
        ("山西", ["太原", "大同", "阳泉", "长治", "晋城", "朔州", "晋中", "运城", "忻州", "临汾", "吕梁"]),
        ("内蒙古", ["呼和浩特", "包头", "乌海", "赤峰", "通辽", "鄂尔多斯", "呼伦贝尔", "巴彦淖尔", "乌兰察布"]),
        ("辽宁", ["沈阳", "大连", "鞍山", "抚顺", "本溪", "丹东", "锦州", "营口", "阜新", "辽阳", "盘锦", "铁岭", "朝阳", "葫芦岛"]),
        ("吉林", ["长春", "吉林", "四平", "辽源", "通化", "白山", "松原", "白城", "延边"]),
        ("黑龙江", ["哈尔滨", "齐齐哈尔", "鸡西", "鹤岗", "双鸭山", "大庆", "伊春", "佳木斯", "七台河", "牡丹江", "黑河", "绥化", "大兴安岭"]),
        ("上海", ["上海"]),
        ("江苏", ["南京", "无锡", "徐州", "常州", "苏州", "南通", "连云港", "淮安", "盐城", "扬州", "镇江", "泰州", "宿迁"]),
        ("浙江", ["杭州", "宁波", "温州", "嘉兴", "湖州", "绍兴", "金华", "衢州", "舟山", "台州", "丽水"]),
        ("安徽", ["合肥", "芜湖", "蚌埠", "淮南", "马鞍山", "淮北", "铜陵", "安庆", "黄山", "滁州", "阜阳", "宿州", "六安", "亳州", "池州", "宣城"]),
        ("福建", ["福州", "厦门", "莆田", "三明", "泉州", "漳州", "南平", "龙岩", "宁德"]),
        ("江西", ["南昌", "景德镇", "萍乡", "九江", "新余", "鹰潭", "赣州", "吉安", "宜春", "抚州", "上饶"]),
        ("山东", ["济南", "青岛", "淄博", "枣庄", "东营", "烟台", "潍坊", "济宁", "泰安", "威海", "日照", "临沂", "德州", "聊城", "滨州", "菏泽"]),
        ("河南", ["郑州", "开封", "洛阳", "平顶山", "安阳", "鹤壁", "新乡", "焦作", "濮阳", "许昌", "漯河", "三门峡", "南阳", "商丘", "信阳", "周口", "驻马店", "济源"]),
        ("湖北", ["武汉", "黄石", "十堰", "宜昌", "襄阳", "鄂州", "荆门", "孝感", "荆州", "黄冈", "咸宁", "随州", "恩施"]),
        ("湖南", ["长沙", "株洲", "湘潭", "衡阳", "邵阳", "岳阳", "常德", "张家界", "益阳", "郴州", "永州", "怀化", "娄底", "湘西"]),
        ("广东", ["广州", "深圳", "珠海", "汕头", "佛山", "韶关", "湛江", "肇庆", "江门", "茂名", "惠州", "梅州", "汕尾", "河源", "阳江", "清远", "东莞", "中山", "潮州", "揭阳", "云浮"]),
        ("广西", ["南宁", "柳州", "桂林", "梧州", "北海", "防城港", "钦州", "贵港", "玉林", "百色", "贺州", "河池", "来宾", "崇左"]),
        ("海南", ["海口", "三亚", "三沙", "儋州"]),
        ("重庆", ["重庆"]),
        ("四川", ["成都", "自贡", "攀枝花", "泸州", "德阳", "绵阳", "广元", "遂宁", "内江", "乐山", "南充", "眉山", "宜宾", "广安", "达州", "雅安", "巴中", "资阳", "阿坝", "甘孜", "凉山"]),
        ("贵州", ["贵阳", "六盘水", "遵义", "安顺", "毕节", "铜仁", "黔西南", "黔东南", "黔南"]),
        ("云南", ["昆明", "曲靖", "玉溪", "保山", "昭通", "丽江", "普洱", "临沧", "楚雄", "红河", "文山", "西双版纳", "大理", "德宏", "怒江", "迪庆"]),
        ("西藏", ["拉萨", "日喀则", "昌都", "林芝", "山南", "那曲", "阿里"]),
        ("陕西", ["西安", "铜川", "宝鸡", "咸阳", "渭南", "延安", "汉中", "榆林", "安康", "商洛"]),
        ("甘肃", ["兰州", "嘉峪关", "金昌", "白银", "天水", "武威", "张掖", "平凉", "酒泉", "庆阳", "定西", "陇南", "临夏", "甘南"]),
        ("青海", ["西宁", "海东", "海北", "黄南", "海南", "果洛", "玉树", "海西"]),
        ("宁夏", ["银川", "石嘴山", "吴忠", "固原", "中卫"]),
        ("新疆", ["乌鲁木齐", "克拉玛依", "吐鲁番", "哈密", "昌吉", "博尔塔拉", "巴音郭楞", "阿克苏", "克孜勒苏", "喀什", "和田", "伊犁", "塔城", "阿勒泰"]),
        ("香港", ["香港"]),
        ("澳门", ["澳门"]),
        ("台湾", ["台北", "新北", "桃园", "台中", "台南", "高雄", "基隆", "新竹", "嘉义"])
    ]

    static var provinces: [String] { data.map(\.0) }

    static func cities(_ province: String) -> [String] {
        data.first { $0.0 == province }?.1 ?? []
    }
}
