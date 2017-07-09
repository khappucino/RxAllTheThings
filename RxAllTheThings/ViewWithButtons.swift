import Foundation
import UIKit
import RxSwift
import RxCocoa

struct ViewWithButtonsPayload {
    let button1Name: String
    let button2Name: String
}

class ViewWithButtons: UIView {
    let button1: UIButton
    let button2: UIButton
    var viewStatePayload: ViewWithButtonsPayload!
    
    required init?(coder aDecoder: NSCoder) {
        button1 = UIButton(frame: .zero)
        button2 = UIButton(frame: .zero)
        
        super.init(coder: aDecoder)
        
        button1.translatesAutoresizingMaskIntoConstraints = false
        button1.backgroundColor = UIColor.gray
        
        button2.translatesAutoresizingMaskIntoConstraints = false
        button2.backgroundColor = UIColor.darkGray
        
        addSubview(button1)
        addSubview(button2)
        
        backgroundColor = UIColor.gray
        
        translatesAutoresizingMaskIntoConstraints = false

        button1.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        button1.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        button1.topAnchor.constraint(equalTo: topAnchor).isActive = true
        button1.bottomAnchor.constraint(equalTo: button2.topAnchor).isActive = true
        
        button2.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        button2.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        button2.topAnchor.constraint(equalTo: button1.bottomAnchor).isActive = true
        button2.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
    }
    
    func configure(buttonPayload: ViewWithButtonsPayload) {
        viewStatePayload = buttonPayload
        button1.setTitle(viewStatePayload.button1Name, for: .normal)
        button2.setTitle(viewStatePayload.button2Name, for: .normal)
    }
    
    func eventObs() -> Observable<Event> {
        let button1Events = button1.rx.controlEvent(.touchUpInside).map { _ -> Event in
            let name = self.viewStatePayload.button1Name
            return Event.userSelected(name)
        }
        
        let button2Events = button2.rx.controlEvent(.touchUpInside).map { _ -> Event in
            let name = self.viewStatePayload.button2Name
            return Event.userSelected(name)
        }
        
        return Observable.merge([button1Events, button2Events])
    }
}

