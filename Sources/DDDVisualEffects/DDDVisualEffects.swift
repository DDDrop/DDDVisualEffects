import SwiftUI

#if os(macOS)
//struct BlurViewRepresentable: NSViewRepresentable {
//    let material: NSVisualEffectView.Material
//    let blendingMode: NSVisualEffectView.BlendingMode
//
//    func makeNSView(context: Context) -> NSVisualEffectView {
//        let view = NSVisualEffectView()
//        view.material = material
//        view.blendingMode = blendingMode
//        view.state = NSVisualEffectView.State.active
//        return view
//    }
//
//    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
//        nsView.material = material
//        nsView.blendingMode = blendingMode
//    }
//}
//
//struct BlendingModeKey: EnvironmentKey {
//    static var defaultValue: NSVisualEffectView.BlendingMode = .behindWindow
//}
//
//extension EnvironmentValues {
//    var blendingMode: NSVisualEffectView.BlendingMode {
//        get {
//            self[BlendingModeKey.self]
//        }
//        set {
//            self[BlendingModeKey.self] = newValue
//        }
//    }
//}
//
//public struct BlurEffectModifier: ViewModifier {
//    public init() {}
//
//    public func body(content: Content) -> some View {
//        content.overlay(BlurViewRepresentable(material: .contentBackground, blendingMode: .withinWindow))
//    }
//}
//
//
//public extension View {
//    func blurEffect() -> some View {
//        ModifiedContent(content: self, modifier: BlurEffectModifier())
//    }
//}

struct VisualEffectMaterialKey: EnvironmentKey {
    typealias Value = NSVisualEffectView.Material?
    static var defaultValue: Value = nil
}

struct VisualEffectBlendingKey: EnvironmentKey {
    typealias Value = NSVisualEffectView.BlendingMode?
    static var defaultValue: Value = nil
}

struct VisualEffectEmphasizedKey: EnvironmentKey {
    typealias Value = Bool?
    static var defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var visualEffectMaterial: NSVisualEffectView.Material? {
        get { self[VisualEffectMaterialKey.self] }
        set { self[VisualEffectMaterialKey.self] = newValue }
    }
    
    var visualEffectBlending: NSVisualEffectView.BlendingMode? {
        get { self[VisualEffectBlendingKey.self] }
        set { self[VisualEffectBlendingKey.self] = newValue }
    }
    
    var visualEffectEmphasized: Bool? {
        get { self[VisualEffectEmphasizedKey.self] }
        set { self[VisualEffectEmphasizedKey.self] = newValue }
    }
}

struct VisualEffectView<Content: View>: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let isEmphasized: Bool
    private let content: Content
    
    fileprivate init(
        content: Content,
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode,
        emphasized: Bool) {
        self.content = content
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = emphasized
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        let wrapper = NSHostingView(rootView: content)
        
        // Not certain how necessary this is
        view.autoresizingMask = [.width, .height]
        wrapper.autoresizingMask = [.width, .height]
        wrapper.frame = view.bounds
        
        view.addSubview(wrapper)
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = context.environment.visualEffectMaterial ?? material
        nsView.blendingMode = context.environment.visualEffectBlending ?? blendingMode
        nsView.isEmphasized = context.environment.visualEffectEmphasized ?? isEmphasized
    }
}

extension View {
    func visualEffect(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false
    ) -> some View {
        VisualEffectView(
            content: self,
            material: material,
            blendingMode: blendingMode,
            emphasized: emphasized
        )
    }
}
#endif

#if os(iOS)
struct BlurEffectStyleKey: EnvironmentKey {
    static var defaultValue: UIBlurEffect.Style = .systemMaterial
}

struct VibrancyEffectStyleKey: EnvironmentKey {
    static var defaultValue: UIVibrancyEffectStyle?
}

extension EnvironmentValues {
    var blurEffectStyle: UIBlurEffect.Style {
        get {
            self[BlurEffectStyleKey.self]
        }
        set {
            self[BlurEffectStyleKey.self] = newValue
        }
    }
}

extension EnvironmentValues {
    var vibrancyEffectStyle: UIVibrancyEffectStyle? {
        get {
            self[VibrancyEffectStyleKey.self]
        }
        set {
            self[VibrancyEffectStyleKey.self] = newValue
        }
    }
}


public struct BlurEffectModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .overlay(BlurVisualEffectViewRepresentable())
    }
}

struct BlurVisualEffectViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: context.environment.blurEffectStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: context.environment.blurEffectStyle)
    }
}


public struct VibrancyEffectModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .hidden()
            .overlay(VibrancyVisualEffectViewRepresentable(content: content))
    }
}

struct VibrancyVisualEffectViewRepresentable<Content: View>: UIViewRepresentable {
    init(content: Content) {
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(content: content)
    }
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        context.coordinator.configureVisualEffectView(from: context)
        
        return context.coordinator.visualEffectView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        context.coordinator.configureVisualEffectView(from: context)
    }
    
    private let content: Content
}

extension VibrancyVisualEffectViewRepresentable {
    final class Coordinator {
        let visualEffectView = UIVisualEffectView()
        
        init(content: Content) {
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.view.backgroundColor = nil
            
            visualEffectView.contentView.addSubview(hostingController.view)
        }
        
        func configureVisualEffectView(from context: Context) {
            let blurEffect = UIBlurEffect(style: context.environment.blurEffectStyle)
            
            if let vibrancyEffectStyle = context.environment.vibrancyEffectStyle {
                visualEffectView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyEffectStyle)
            } else {
                visualEffectView.effect = UIVibrancyEffect(blurEffect: blurEffect)
            }
        }
    }
}

public extension View {
    func blurEffect() -> some View {
        ModifiedContent(content: self, modifier: BlurEffectModifier())
    }
    
    func blurEffectStyle(_ style: UIBlurEffect.Style) -> some View {
        environment(\.blurEffectStyle, style)
    }
    
    func vibrancyEffect() -> some View {
        ModifiedContent(content: self, modifier: VibrancyEffectModifier())
    }
    
    func vibrancyEffectStyle(_ style: UIVibrancyEffectStyle) -> some View {
        environment(\.vibrancyEffectStyle, style)
    }
}

#endif
