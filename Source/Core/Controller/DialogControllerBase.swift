//
//  DialogControllerBase.swift
//  Reactant
//
//  Created by Filip Dolnik on 08.11.16.
//  Copyright © 2016 Brightify. All rights reserved.
//

import UIKit

open class DialogControllerBase<STATE, ROOT: UIView>: ControllerBase<STATE, ROOT> where ROOT: Component {
    
    public var dialogView: DialogView
    
    open override var configuration: Configuration {
        didSet {
            dialogView.configuration = configuration
        }
    }

    public override init(title: String = "", root: ROOT = ROOT()) {
        dialogView = DialogView(content: root)
        
        super.init(title: title, root: root)
        
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
    }
    
    open override func loadView() {
        view = ControllerRootViewContainer().with(configuration: configuration)
        
        view.addSubview(dialogView)
    }
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let dismissalListener = presentingViewController as? DialogDismissalListener
        dismissalListener?.dialogWillDismiss()
        super.dismiss(animated: flag) {
            dismissalListener?.dialogDidDismiss()
            completion?()
        }
    }
    
    open override func updateRootViewConstraints() {
        dialogView.snp.updateConstraints { make in
            make.edges.equalTo(view)
        }
    }
}
