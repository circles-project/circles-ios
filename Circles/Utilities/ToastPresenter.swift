//
//  ToastPresenter.swift
//  Circles
//
//  Created by Charles Wright on 6/7/24.
//

import Foundation
import JDStatusBarNotification

public class ToastPresenter {
    public static var shared = ToastPresenter()
    public var delay = 3.0
    
    // FIXME: Add styling to make this look nice
    
    @MainActor
    public func showToast(message: String) async {
        NotificationPresenter.shared.present(message)
        NotificationPresenter.shared.dismiss(animated: true, after: delay)
    }
    
    public func showToast(message: String) {
        NotificationPresenter.shared.present(message)
        NotificationPresenter.shared.dismiss(animated: true, after: delay)
    }
}
