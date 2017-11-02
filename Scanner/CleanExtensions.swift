//
//  CleanExtensions.swift
//  Scanner
//
//  Created by Himanshu Tantia on 2/11/17.
//  Copyright © 2017 Kreativ Apps, LLC. All rights reserved.
//

import UIKit

protocol Identifiable {
    static var identifier: String { get }
}
extension Identifiable {
    static var identifier: String {
        return String(describing: self)
    }
}


extension UITableViewCell : Identifiable { }
extension UITableView {
    
    // MARK: - Cell Instantiation from Generics
    func dequeueReusableCell<T: UITableViewCell>() -> T /*where T: Identifiable*/ {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.identifier) as? T else {
            fatalError("Couldn't instantiate UITableViewCell with identifier \(T.identifier) ")
        }
        return cell
    }
    
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T /*where T: Identifiable*/ {
        let reusableCell = self.dequeueReusableCell(withIdentifier: T.identifier, for: indexPath)
        guard let cell = reusableCell as? T else {
            fatalError("Couldn't instantiate UITableViewCell with identifier \(T.identifier) ")
        }
        return cell
    }
}

extension UIViewController : Identifiable { }
extension Identifiable where Self: UIViewController {
    static var identifier: String {
        return String(describing: self)
    }
}

extension UIStoryboard {
    
    /// The uniform place where we state all the storyboards we have in our application
    
    enum Identifier: String {
        case main
        
        var name: String {
            return rawValue.capitalized
        }
    }
    
    
    // MARK: - Convenience Initializers
    
    convenience init(storyboard: Identifier, bundle: Bundle? = Bundle.main) {
        self.init(name: storyboard.name, bundle: bundle)
    }
    
    
    // MARK: - Class Functions
    
    class func storyboard(_ storyboard: Identifier, bundle: Bundle? = Bundle.main) -> UIStoryboard {
        return UIStoryboard(name: storyboard.name, bundle: bundle)
    }
    
    
    // MARK: - View Controller Instantiation from Generics
    
    func instantiateViewController<T: UIViewController>() -> T /*where T: Identifiable*/ {
        guard let viewController = self.instantiateViewController(withIdentifier: T.identifier) as? T else {
            fatalError("Couldn't instantiate view controller with identifier \(T.identifier) ")
        }
        
        return viewController
    }
}
