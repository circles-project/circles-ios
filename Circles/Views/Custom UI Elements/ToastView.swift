//
//  ToastView.swift
//  Circles
//
//  Created by Dmytro Ryshchuk on 5/30/24.
//

import SwiftUI
import JDStatusBarNotification

private enum DefaultColors {
    case text
    case background
    
    var color: UIColor {
        switch self {
        case .text: return .lightText
        case .background: return .lightGray
        }
    }
}

private enum DefaultFonts {
    case title
    case subtitle
    
    var font: UIFont {
        switch self {
        case .title: UIFont.preferredFont(forTextStyle: .callout)
        case .subtitle: UIFont.preferredFont(forTextStyle: .subheadline)
        }
    }
}

struct CustomToastSetup {
    var subtitle: String? = nil
    var image: UIImage? = nil
    var titleFont: UIFont? = DefaultFonts.title.font
    var subtitleFont: UIFont? = DefaultFonts.subtitle.font
    var titleColor: UIColor = DefaultColors.text.color
    var subtitleColor: UIColor = DefaultColors.text.color
    var backgroundColor: UIColor = DefaultColors.background.color
}

struct ToastView: View {
    enum ToastStyle {
        case simple
        case icon /// "icon" style will work only if we set "customToast"
    }
    var titleMessage: String
    var style: ToastStyle
    var customToast: CustomToastSetup?
    var font = Font(DefaultFonts.title.font)
    var textColor = Color(DefaultColors.text.color)
    var backgroundColor = DefaultColors.background.color
    
    private func executeAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NotificationPresenter.shared.dismiss()
        }
    }
    
    private var showTitle: some View {
        Text(titleMessage)
            .font(font)
            .foregroundStyle(textColor)
            .multilineTextAlignment(.center)
            .onAppear {
                executeAfterDelay()
            }
    }
    
    private var simpleToast: some View {
        VStack { }
            .onAppear {
                NotificationPresenter.shared.updateDefaultStyle { style in
                    style.backgroundStyle.backgroundColor = backgroundColor
                    
                    return style
                }
                
                NotificationPresenter.shared.presentSwiftView() {
                    showTitle
                }
                //.backgroundColor = backgroundColor
            }
    }
    
    private var iconToast: some View {
        VStack { }
            .onAppear {
                if let customToast {
                    NotificationPresenter.shared.updateDefaultStyle { style in
                        style.backgroundStyle.backgroundColor = customToast.backgroundColor
                        style.textStyle.textColor = customToast.titleColor
                        style.textStyle.font = customToast.titleFont
                        style.subtitleStyle.textColor = customToast.subtitleColor
                        style.subtitleStyle.font = customToast.subtitleFont
                        
                        return style
                    }
                    
                    if let subtitle = customToast.subtitle {
                        NotificationPresenter.shared.present(titleMessage, subtitle: subtitle)
                    } else {
                        NotificationPresenter.shared.present(titleMessage)
                    }
                    let image = UIImageView(image: customToast.image)
                    NotificationPresenter.shared.displayLeftView(image)
                    
                    executeAfterDelay()
                } else {
                    NotificationPresenter.shared.presentSwiftView() {
                        showTitle
                    }
                }
            }
    }
    
    var body: some View {
        switch style {
        case .simple: simpleToast
        case .icon: iconToast
        }
    }
}

/*
#Preview {
    ToastView(message: "My toast",
              style: .simple)
}
*/
