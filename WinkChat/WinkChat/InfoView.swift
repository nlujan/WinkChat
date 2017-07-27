import UIKit

class InfoView: UIView {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    private static var sharedView: InfoView!

    static func loadFromNib() -> InfoView {
        let nibName = "\(self)".characters.split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! InfoView
    }
    
    static func showIn(viewController: UIViewController, message: String) {

        var displayVC = viewController

        if let tabController = viewController as? UITabBarController {
            displayVC = tabController.selectedViewController ?? viewController
        }

        if sharedView == nil {
            sharedView = loadFromNib()
            sharedView.layer.masksToBounds = false
        }

        sharedView.textLabel.text = message

        if sharedView?.superview == nil {
            sharedView.frame = CGRect(x: 0, y: 0, width: displayVC.view.frame.size.width, height: sharedView.frame.size.height)
            sharedView.alpha = 0.0

            displayVC.view.addSubview(sharedView)
            sharedView.fadeIn()

            // this call needs to be counter balanced on fadeOut [1]
            sharedView.perform(#selector(fadeOut), with: nil, afterDelay: 3.0)
        }
        
    }

    @IBAction func closePressed(_ sender: UIButton) {
        fadeOut()
    }


  // MARK: Animations
    func fadeIn() {
        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 1.0
        })
    }

    @objc func fadeOut() {

        // [1] Counter balance previous perfom:with:afterDelay
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
