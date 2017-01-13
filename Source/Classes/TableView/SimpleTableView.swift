//
//  SimpleTableView.swift
//  Reactant
//
//  Created by Filip Dolnik on 16.11.16.
//  Copyright © 2016 Brightify. All rights reserved.
//

import RxSwift
import RxDataSources

public enum SimpleTableViewAction<HEADER: Component, CELL: Component, FOOTER: Component> {
    case selected(CELL.StateType)
    case headerAction(HEADER.StateType, HEADER.ActionType)
    case rowAction(CELL.StateType, CELL.ActionType)
    case footerAction(FOOTER.StateType, FOOTER.ActionType)
}

open class SimpleTableView<HEADER: UIView, CELL: UIView, FOOTER: UIView>: ViewBase<TableViewState<SectionModel<(header: HEADER.StateType, footer: FOOTER.StateType), CELL.StateType>>, SimpleTableViewAction<HEADER, CELL, FOOTER>>, UITableViewDelegate, ReactantTableView where HEADER: Component, CELL: Component, FOOTER: Component {
    
    public typealias MODEL = CELL.StateType
    public typealias SECTION = SectionModel<(header: HEADER.StateType, footer: FOOTER.StateType), CELL.StateType>
    
    private let cellIdentifier = TableViewCellIdentifier<CELL>()
    private let headerIdentifier = TableViewHeaderFooterIdentifier<HEADER>()
    private let footerIdentifier = TableViewHeaderFooterIdentifier<FOOTER>()
    
    open var edgesForExtendedLayout: UIRectEdge {
        return .all
    }

    open override var actions: [Observable<SimpleTableViewAction<HEADER, CELL, FOOTER>>] {
        return [
            tableView.rx.modelSelected(MODEL.self).map(SimpleTableViewAction.selected)
        ]
    }
    
    public let tableView: UITableView
    
    public let refreshControl: UIRefreshControl?
    public let emptyLabel = UILabel()
    public let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: ReactantConfiguration.global.loadingIndicatorStyle)
    
    private let headerFactory: (() -> HEADER)
    private let footerFactory: (() -> FOOTER)
    
    private let dataSource = RxTableViewSectionedReloadDataSource<SECTION>()
    
    public init(
        cellFactory: @escaping () -> CELL = CELL.init,
        headerFactory: @escaping () -> HEADER = HEADER.init,
        footerFactory: @escaping () -> FOOTER = FOOTER.init,
        style: UITableViewStyle = .plain,
        reloadable: Bool = true)
    {
        self.tableView = UITableView(frame: CGRect.zero, style: style)
        self.headerFactory = headerFactory
        self.footerFactory = footerFactory
        self.refreshControl = reloadable ? UIRefreshControl() : nil
        
        super.init()
        
        dataSource.configureCell = { [cellIdentifier] _, tableView, indexPath, model in
            let cell = tableView.dequeue(identifier: cellIdentifier)
            let component = cell.cachedCellOrCreated(factory: cellFactory)
            component.componentState = model
            component.action.subscribe(onNext: { [weak self] in
                self?.perform(action: .rowAction(model, $0))
            })
                .addDisposableTo(component.stateDisposeBag)
            return cell
        }
    }
    
    open override func loadView() {
        children(
            tableView,
            emptyLabel,
            loadingIndicator
        )
        
        if let refreshControl = refreshControl {
            tableView.children(
                refreshControl
            )
        }
        
        loadingIndicator.hidesWhenStopped = true
        
        ReactantConfiguration.global.emptyListLabelStyle(emptyLabel)
        
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .singleLine
        tableView.delegate = self
        
        tableView.register(identifier: cellIdentifier)
        tableView.register(identifier: headerIdentifier)
        tableView.register(identifier: footerIdentifier)
    }
    
    open override func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
    }
    
    open override func afterInit() {
        tableView.rx.itemSelected
            .subscribe(onNext: { [tableView] in
                tableView.deselectRow(at: $0, animated: true)
            })
            .addDisposableTo(lifetimeDisposeBag)
    }
    
    open override func update() {
        var items: [SECTION] = []
        var emptyMessage = ""
        var loading = false
        
        switch componentState {
        case .items(let models):
            items = models
        case .empty(let message):
            emptyMessage = message
        case .loading:
            loading = true
        }
        
        emptyLabel.text = emptyMessage
        
        if let refreshControl = refreshControl {
            if loading {
                refreshControl.beginRefreshing()
            } else {
                refreshControl.endRefreshing()
            }
        } else {
            if loading {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        }
        
        Observable.just(items)
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(stateDisposeBag)
        
        setNeedsLayout()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutHeaderView()
        layoutFooterView()
    }
    
    @objc public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeue(identifier: headerIdentifier)
        let section = dataSource.sectionModels[section].identity
        let component = header.cachedViewOrCreated(factory: headerFactory)
        component.componentState = section.header
        component.action
            .subscribe(onNext: { [weak self] in
                self?.perform(action: .headerAction(section.header, $0))
            })
            .addDisposableTo(component.stateDisposeBag)

        return header
    }
    
    @objc public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.dequeue(identifier: footerIdentifier)
        let section = dataSource.sectionModels[section].identity
        let component = footer.cachedViewOrCreated(factory: footerFactory)
        component.componentState = section.footer
        component.action
            .subscribe(onNext: { [weak self] in
                self?.perform(action: .footerAction(section.footer, $0))
            })
            .addDisposableTo(component.stateDisposeBag)

        return footer
    }
}