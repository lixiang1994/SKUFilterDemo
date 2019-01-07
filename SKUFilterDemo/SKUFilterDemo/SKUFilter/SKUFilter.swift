//
//  SKUFilter.swift
//  SKUFilterDemo
//
//  Created by 李响 on 2019/1/3.
//  Copyright © 2019 swift. All rights reserved.
//

import Foundation

protocol SKUFilterDelegate: NSObjectProtocol {
    /// 属性集合个数
    func numberOfArrtibutes(_ filter: SKUFilter) -> Int
    /// 属性集合
    func arrtibutes(_ filter: SKUFilter, for index: Int) -> [AnyHashable]
    /// 条件集合个数
    func numberOfConditions(_ filter: SKUFilter) -> Int
    /// 条件集合
    func conditions(_ filter: SKUFilter, for index: Int) -> [AnyHashable]
    
    /// 结果
    func result(_ filter: SKUFilter, for index: Int) -> Any?
}

class SKUFilter {
    
    weak var delegate: SKUFilterDelegate? {
        didSet { reloadData() }
    }
    
    private(set) var selecteds: [IndexPath] = []
    private(set) var available: Set<IndexPath> = []
    private(set) var result: Any?
    
    private var allAvailable: Set<IndexPath> = []
    private var conditions: Set<Condition> = []
    
    init(_ delegate: SKUFilterDelegate) {
        self.delegate = delegate
        reloadData()
    }
    
    /// 刷新数据
    func reloadData() {
        guard let delegate = delegate else {
            // 清理
            selecteds = []
            available = []
            result = nil
            allAvailable = []
            conditions = []
            return
        }
        
        // 清空
        selecteds = []
        available = []
        
        // 条件集合
        var temps = Set<Condition>()
        (0 ..< delegate.numberOfConditions(self)).forEach {
            let conditions = delegate.conditions(self, for: $0)
            
            let arrtibutes: [Attribute] = conditions.enumerated().compactMap {
                guard
                    delegate.numberOfArrtibutes(self) > $0,
                    let index = delegate.arrtibutes(self, for: $0).firstIndex(of: $1) else {
                    return nil
                }
                let indexPath = IndexPath(item: index, section: $0)
                return Attribute(indexPath, $1)
            }
            
            if arrtibutes.count == conditions.count {
                let condition = Condition(
                    arrtibutes: arrtibutes,
                    indexs: arrtibutes.map { $0.indexPath.item },
                    result: delegate.result(self, for: $0)
                )
                temps.insert(condition)
            }
        }
        conditions = temps
        
        // 可选集合
        available = Set<IndexPath>(temps.flatMap {
            $0.indexs.enumerated().map {
                IndexPath(item: $1, section: $0)
            }
        })
        
        allAvailable = available
    }
    
    /// 选择
    ///
    /// - Parameter indexPath: 位置
    func selected(_ indexPath: IndexPath) {
        guard available.contains(indexPath) else {
            // 不可选
            return
        }
        guard
            let section = delegate?.numberOfArrtibutes(self),
            let item = delegate?.arrtibutes(self, for: indexPath.section).count,
            indexPath.section < section,
            indexPath.item < item else {
            // 越界
            return
        }
        guard !selecteds.contains(indexPath) else {
            // 已选
            selecteds.removeAll { $0 == indexPath }
            updateAvailable()
            updateResult()
            return
        }
        
        if let last = selecteds.lastIndex(where: { $0.section == indexPath.section }) {
            // 切换
            selecteds.append(indexPath)
            selecteds.remove(at: last)
            updateAvailable()
            updateResult()
            
        } else {
            // 新增
            selecteds.append(indexPath)
            available.formIntersection(available(indexPath, with: selecteds))
            updateResult()
        }
    }
}

extension SKUFilter {
    /// 更新可选集合
    private func updateAvailable() {
        guard !selecteds.isEmpty else {
            available = allAvailable
            return
        }
        
        var temps: [IndexPath] = []
        var set: Set<IndexPath> = []
        selecteds.forEach {
            temps.append($0)
            let available = self.available($0, with: temps)
            set = set.isEmpty ? available : set.intersection(available)
        }
        available = set
    }
    
    /// 获取可选集合
    ///
    /// - Parameters:
    ///   - selected: 当前选择
    ///   - selecteds: 已选集合
    /// - Returns: 可选集合
    private func available(_ selected: IndexPath, with selecteds: [IndexPath]) -> Set<IndexPath> {
        var temps = Set<IndexPath>()
        
        conditions.forEach { (condition) in
            guard
                condition.indexs.count > selected.section,
                condition.indexs[selected.section] == selected.item else {
                return
            }
            
            condition.arrtibutes.forEach { (attribute) in
                if attribute.indexPath.section == selected.section {
                    temps.insert(attribute.indexPath)
                    
                } else {
                    let flag = selecteds.contains {
                        (condition.indexs.count > $0.section &&
                        condition.indexs[$0.section] == $0.item) ||
                        $0.section == attribute.indexPath.section
                    }
                    if flag { temps.insert(attribute.indexPath) }
                }
            }
        }
        allAvailable
            .filter({ $0.section == selected.section })
            .forEach({ temps.insert($0) })
        return temps
    }
    
    /// 更新结果
    private func updateResult() {
        guard selecteds.count == delegate?.numberOfArrtibutes(self) else {
            result = nil
            return
        }
        
        let items = selecteds.sorted { $0.section < $1.section }.map { $0.item }
        result = conditions.first { $0.indexs == items }?.result
    }
}

extension SKUFilter {
    
    struct Condition: Hashable, Equatable {
        let arrtibutes: [Attribute]
        let indexs: [Int]
        let result: Any?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(arrtibutes)
            hasher.combine(indexs)
        }
        
        static func == (lhs: SKUFilter.Condition,
                        rhs: SKUFilter.Condition) -> Bool {
            return lhs.arrtibutes == rhs.arrtibutes
                && lhs.indexs == rhs.indexs
        }
    }
    
    struct Attribute: Hashable, Equatable {
        let indexPath: IndexPath
        let value: AnyHashable
        
        init(_ indexPath: IndexPath, _ value: AnyHashable) {
            self.indexPath = indexPath
            self.value = value
        }
    }
}
