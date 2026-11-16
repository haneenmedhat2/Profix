//
//  BaseNav.swift
//  Waraqa
//
//  Created by Haneen on 07/08/2025.
//

import Foundation
import UIKit

class BaseNav: UINavigationController {
    
    //MARK: - Properties -
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    //MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupGesture()
        self.handleAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        handleAppearance()
    }
    
    
    //MARK: - Design -
    
    func handleAppearance() {
        let backButtonImage = UIImage(resource: .backArrow)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .main
        appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white,  .font:UIFont.myMediumFont(ofSize: 16)]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .white


        navigationBar.semanticContentAttribute = Language.isRTL() ? .forceRightToLeft : .forceLeftToRight
        view.semanticContentAttribute = navigationBar.semanticContentAttribute

        addStatusBarBackground()
    }

    
    private func addStatusBarBackground() {
        guard let window = view.window ?? UIApplication.shared.windows.first else { return }

        let height = window.safeAreaInsets.top

        let bar = UIView(frame: CGRect(x: 0, y: 0, width: window.frame.width, height: height))
        bar.backgroundColor = .main
        bar.tag = 999
        bar.isUserInteractionEnabled = false

        if window.viewWithTag(999) == nil {
            window.addSubview(bar)
        }
    }


//    func handleAppearance() {
//        
//        let appearance = UINavigationBarAppearance()
//        var backButtonImage: UIImage?
//        
//        backButtonImage =  Language.isRTL() ? UIImage(named: "enBackBtn") : UIImage(named: "arBackBtn")
//        
//        guard let backImage = backButtonImage else {
//            print("Back button image not found")
//            return
//        }
//        
//        backImage.withTintColor(.white)
//        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
//        
//        appearance.titleTextAttributes = [.foregroundColor: UIColor.label,
//                                          .font: UIFont.boldSystemFont(ofSize: 16)]
//        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label,
//                                               .font: UIFont.boldSystemFont(ofSize: 26)]
//        
//        appearance.shadowColor = .clear
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//        UINavigationBar.appearance().compactAppearance = appearance
//        UINavigationBar.appearance().semanticContentAttribute = Language.isRTL() ? .forceRightToLeft : .forceLeftToRight
//        
//        self.navigationBar.tintColor = .label
//        appearance.backgroundColor = UIColor(resource: .mainBackGround)
//    }
    private func setupGesture() {
        interactivePopGestureRecognizer?.delegate = self
        self.view.semanticContentAttribute = Language.isRTL() ? .forceRightToLeft : .forceLeftToRight
    }
    
    
}
extension BaseNav: UIGestureRecognizerDelegate {}
