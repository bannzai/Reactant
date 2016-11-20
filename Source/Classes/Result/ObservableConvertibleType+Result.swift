//
//  ObservableConvertibleType+Result.swift
//  Reactant
//
//  Created by Filip Dolnik on 20.11.16.
//  Copyright © 2016 Brightify. All rights reserved.
//

import RxSwift
import RxOptional
import Result

public extension ObservableConvertibleType where E: ResultProtocol {
    
    public func filterError() -> Observable<E.Value> {
        return asObservable().map { $0.value }.filterNil()
    }
    
    public func errorOnly() -> Observable<E.Error> {
        return asObservable().map { $0.error }.filterNil()
    }
    
    public func map<T>(_ transform: @escaping (E.Value) -> T) -> Observable<Result<T, E.Error>> {
        return asObservable().map { $0.map(transform) }
    }
    
    public func mapError<T: Error>(_ transform: @escaping @autoclosure (E.Error) -> T) -> Observable<Result<E.Value, T>> {
        return asObservable().map { $0.mapError(transform) }
    }
    
    public func rewriteValue<T>(newValue: T) -> Observable<Result<T, E.Error>> {
        return map { _ in newValue }
    }
    
    public func recover(_ value: E.Value) -> Observable<E.Value> {
        return asObservable().map { $0.value ?? value }
    }
    
    public func replaceResultErrorWithNil() -> Observable<Self.E.Value?> {
        return asObservable().map { $0.value }
    }
}
