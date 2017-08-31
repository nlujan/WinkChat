import UIKit

class InfoView: UIView {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    private static var sharedView: InfoView!

    private static func loadFromNib() -> InfoView {
        let nibName = "\(self)".characters.split{ $0 == "." }.map(String.init).last!
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
            sharedView.frame = CGRect(x: 0, y: 0 + displayVC.topLayoutGuide.length, width: displayVC.view.frame.size.width, height: 45)
            sharedView.alpha = 0.0

            displayVC.view.addSubview(sharedView)
            sharedView.fadeIn()

            sharedView.perform(#selector(fadeOut), with: nil, afterDelay: 3.0)
        }
        
    }

    @IBAction func closePressed(_ sender: UIButton) {
        fadeOut()
    }

    private func fadeIn() {
        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 1.0
        })
    }

    @objc private func fadeOut() {

        NSObject.cancelPreviousPerformRequests(withTarget: self)

        UIView.animate(withDuration: 0.33, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}
