//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Jordan Leahy on 6/10/18.
//  Copyright © 2018 Treehouse Island, Inc. All rights reserved.
//

import Foundation

enum VendingSelection {
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum
}

protocol VendingItem {
    var price: Double { get }
    var quantity: Int { get set }
}

//Each VendingMachine should have a selection: and this should be an array that we have defined in our VendingMaching enum
//VendingMachine also needs an inventory which is a dictionary with a keys of Vending Selection and Vendingitem as value
protocol VendingMachine {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
    
    //A vending machine needs to set itself up from some inventory source.
    init(inventory: [VendingSelection: VendingItem])
    
    //A vending machine needs to vend items and can lead to many errors
    func vend(_ selection: VendingSelection, _ quantity: Int) throws
    func deposit(_ amount: Double)
}

