import UIKit
import HealthKit
import SwiftUI

class ViewController: UIViewController {

    @IBOutlet weak var container: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        print("1984 viewdidload")
        let childView = UIHostingController(rootView: CountSteps())
        addChild(childView)
        childView.view.frame  = container.bounds
        container.addSubview(childView.view)
        }
}
