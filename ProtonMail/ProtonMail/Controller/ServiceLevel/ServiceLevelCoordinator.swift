//
//  ServiceLevelCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class BuyMoreCoordinator: Coordinator {
    func make<SomeCoordinator>(coordinatorFor next: Never) -> SomeCoordinator where SomeCoordinator : Coordinator {
        fatalError()
    }
    
    init() {
        let superController = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewControllerBase.self)
        object_setClass(superController, BuyMoreViewController.self)
        if let subscription = ServicePlanDataService.shared.currentSubscription {
            (superController as! BuyMoreViewController).setup(with: subscription)
        }
        self.controller = superController
    }
    
    weak var controller: UIViewController!
    
    typealias Destination = Never
}


class PlanDetailsCoordinator: Coordinator {
    weak var controller: UIViewController!
    
    typealias Destination = Never
    
    func make<SomeCoordinator>(coordinatorFor next: PlanDetailsCoordinator.Destination) -> SomeCoordinator {
        fatalError()
    }
    
    init(forPlan plan: ServicePlan) {
        let superController = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewControllerBase.self)
        object_setClass(superController, PlanDetailsViewController.self)
        (superController as! PlanDetailsViewController).setup(with: plan)
        self.controller = superController
    }
}

class ServiceLevelCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: ServiceLevelCoordinator.Destination) -> SomeCoordinator {
        switch next {
        case .buyMore:
            return BuyMoreCoordinator() as! SomeCoordinator
        case .details(of: let plan):
            return PlanDetailsCoordinator(forPlan: plan) as! SomeCoordinator
        }
    }
    
    weak var controller: UIViewController!
    
    init() {
        let controller = UIStoryboard(name: "ServiceLevel", bundle: .main).make(StorefrontCollectionViewController.self)
        let storefront = Storefront(subscription: ServicePlanDataService.shared.currentSubscription!)
        controller.viewModel = StorefrontViewModel(storefront: storefront)
        self.controller = controller
    }
    
    enum Destination {
        case details(of: ServicePlan)
        case buyMore
    }
}
