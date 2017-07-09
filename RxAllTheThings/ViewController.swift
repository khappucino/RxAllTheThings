import UIKit
import Foundation
import RxSwift
import RxCocoa

struct CategoryPage {
    let name: String
}

enum Event {
    case noop
    case load(String)
    case loadFetched(String)
    case userSelected(String)
    case submit()
}

enum VCState {
    case noop
    case startedLoading
    case finishedLoading
    case loaded(CategoryPage)
    case completedSubmit
}

class Service {
    func getInitialValue(value: String) -> Observable<String> {
        return Observable.just("\(value) InitialValue")
    }
    
    func updateValueOnServer(value: String) -> Observable<String> {
        return Observable.just("\(value) Succeeded")
    }
}

class Kitchen {
    let service = Service()
    
    func bindTo(event: Observable<Event>) -> Observable<VCState> {
        return event.flatMap({ (event) -> Observable<Event> in
            return self.convertEvents(event: event)
        })
        .scan(("", Event.noop), accumulator: { (currentValueTuple, event) -> (String, Event) in
            return self.updateCurrentState(currentValue: currentValueTuple.0, event: event)
        })
        .flatMap { (currentValue, event) -> Observable<VCState> in
            self.convertCurrentValueAndEventsIntoVCState(currentValue: currentValue, event: event)
        }
        
    }

    func convertEvents(event: Event) -> Observable<Event> {
        switch event {
        case .load(let value):
            return self.service.getInitialValue(value: value).map { fetchedValue in
                return Event.loadFetched(fetchedValue)
            }.startWith(event)
        default:
            return Observable.just(event)
        }
    }
    
    func updateCurrentState(currentValue: String, event: Event) -> (String, Event) {
        switch event {
        case .loadFetched(let fetchedValue):
            return (fetchedValue, event)
        case .userSelected(let appendingValue):
            let newValue = currentValue + " " + appendingValue
            return (newValue, event)
        default:
            return (currentValue, event)
        }
    }
    
    func convertCurrentValueAndEventsIntoVCState(currentValue: String, event: Event) -> Observable<VCState> {
        switch event {
        case .load(_):
            return Observable.just(.startedLoading)
        case .loadFetched(_):
            return self.handleUpdateValue(value: currentValue).concat(Observable.just(.finishedLoading))
        case .userSelected(_):
            return self.handleUpdateValue(value: currentValue)
        case .submit:
            return self.handleSubmit(value: currentValue)
        default:
            return Observable.just(.noop)
        }
    }
    
    func handleSubmit(value: String) -> Observable<VCState> {
        return service.updateValueOnServer(value: value).map({ (currentValue) -> VCState in
            return VCState.loaded(CategoryPage(name: currentValue))
        })
        .startWith(VCState.startedLoading)
        .concat(Observable.just(.finishedLoading))
        .concat(Observable.just(.completedSubmit))
    }
    
    func handleUpdateValue(value: String) -> Observable<VCState> {
        let categoryPage = CategoryPage(name: value)
        return Observable.just(VCState.loaded(categoryPage))
    }

}

class ViewController: UIViewController {
    @IBOutlet weak var booton: UIButton!
    @IBOutlet weak var viewWithButtons: ViewWithButtons!
    @IBOutlet weak var outputLabel: UILabel!
    let kitchen = Kitchen()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        let allTheEvents = mergeAllTheStreams()
        
        let vcStateObs = self.kitchen.bindTo(event: allTheEvents)

        vcStateObs.debug().subscribe(onNext: { (vcstate) in
            switch vcstate {
            case .startedLoading:
                break
            case .finishedLoading:
                break
            case .loaded(let categoryPage):
                self.outputLabel.text = categoryPage.name
            case .completedSubmit:
                break
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    private func configure() {
        let viewWithButtonsPayload = ViewWithButtonsPayload(button1Name: "button1", button2Name: "button2")
        viewWithButtons.configure(buttonPayload: viewWithButtonsPayload)
    }
    
    private func mergeAllTheStreams() -> Observable<Event> {
        let loadObs = Observable.just(Event.load("begin"))
        let bootonclicked = booton.rx.controlEvent(UIControlEvents.touchUpInside)
            .map { _ in
                return Event.submit()
        }
        let viewWithButtonsObservables = viewWithButtons.eventObs()
        
        let allTheEvents = Observable.merge([loadObs, bootonclicked, viewWithButtonsObservables])
        return allTheEvents
    }

}

