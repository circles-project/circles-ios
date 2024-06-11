//
//  ToastPresenter.swift
//  Circles
//
//  Created by Charles Wright on 6/7/24.
//

import Foundation
import JDStatusBarNotification

public struct CustomToastSetup {
    var image: UIImage? = nil
    var titleFont: UIFont? = UIFont.systemFont(ofSize: 12, weight: .medium)
    var subtitleFont: UIFont? = UIFont.systemFont(ofSize: 10)
    var titleColor: UIColor = .gray
    var subtitleColor: UIColor = .systemGray
    var backgroundColor: UIColor = .systemBackground
}

public class ToastPresenter {
    public static var shared = ToastPresenter()
    public var delay = 3.0
    
    @MainActor
    public func showToast(message: String,
                          subtitle: String? = nil,
                          customToast: CustomToastSetup? = nil) async {
        setupToast(with: message, subtitle: subtitle, customToast: customToast)
    }
    
    public func showToast(message: String,
                          subtitle: String? = nil,
                          customToast: CustomToastSetup? = nil) {
        setupToast(with: message, subtitle: subtitle, customToast: customToast)
    }
    
    private func setupToast(with message: String,
                            subtitle: String? = nil,
                            customToast: CustomToastSetup? = nil) {
        NotificationPresenter.shared.updateDefaultStyle { style in
            if let customToast {
                style.backgroundStyle.backgroundColor = customToast.backgroundColor
                style.textStyle.textColor = customToast.titleColor
                style.textStyle.font = customToast.titleFont
                style.subtitleStyle.textColor = customToast.subtitleColor
                style.subtitleStyle.font = customToast.subtitleFont
            }
            
            return style
        }

        if let subtitle {
            NotificationPresenter.shared.present(message, subtitle: subtitle)
        } else {
            NotificationPresenter.shared.present(message)
        }
        
        if let toastImage = customToast?.image {
            let image = UIImageView(image: toastImage)
            NotificationPresenter.shared.displayLeftView(image)
        }
        NotificationPresenter.shared.dismiss(animated: true, after: delay)
    }
}
