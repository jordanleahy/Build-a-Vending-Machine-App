//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Jordan Leahy on 6/10/18.
//  Copyright © 2018 Treehouse Island, Inc. All rights reserved.
//

/*
 Helpful Notes
 - Deciding on Object Type: Value types such as a struct or enum are things.  Reference types or classes do things.
 - Classes are good at modeling state, the particular values in our data model at a point in time.
 - In Swift, there is no nice way to ask an enum for how many members and what those members are
 - if a variable in a protocol is read only, change it to a constant in the conforming object
 - Whenever you implement an initializer that is defined as a protocol requirement, you have to put the required keyword.
 - Property List: Organizes data into named values and lists of values.
 - Hard coding the means to obtain data inside the class that uses the data is the wrong approach
 - An instance method is a method that is called on an instance of a particular type
 - A type method is associated with the type itself.  You add static, if it is a struct or class before the method name.
 - NSDictionary has a initializer method, Contents of File that takes a string, containing a path to a file. It then returns a fully initialized dictionary instance with the contents of that file.
 - An array can only contain a single type.
 - This is operator returns true if the type matches a type we specify and false if not. It can check on subclass types if an instance is of the base class
 - NSDictionary in Swift is more specifically represented as NSObject to AnyObject.  NSObject is an Objective C tyoe that is the base class for every object in the language
 - AnyObject represents any class in Swift
 - static keyword before func is used to indicate a type method.  Type Methods are called on the actual type, in and of itself.
 - AnyObject represents a class type
 - Retrieving a value from a dictionary using a key always returns an optional because that key may not exist.
 - Once you assign a rawValue to an enum, it also gets an initializer method that allows you to pass in a rawValue and returns and enum case
 */

import Foundation
import UIKit

//rawValue of type string
enum VendingSelection: String {
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
    
    //Return UIImage which is used to represent images in iOS.  UIImage is used to create images from image files, vector drawings, raw image data, etc.
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) { // Loading and Caching Images: Returns the image object associated with the specified filename
            return image
        } else {
            return #imageLiteral(resourceName: "default")
        }
    }
}

protocol VendingItem {
    var price: Double { get }
    var quantity: Int { get set }
}

//Each VendingMachine should have a selection: and this should be an array that we have defined in our VendingMaching enum
//VendingMachine also needs an inventory which is a dictionary with a keys of Vending Selection and Vendingitem as value
//The VendingMaching protocol is a model/blueprint and NOT the implementation
protocol VendingMachine {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
    
    //A vending machine needs to set itself up from some inventory source.
    init(inventory: [VendingSelection: VendingItem])
    
    //A vending machine needs to vend items and can lead to many errors so we add throws
    func vend(selection: VendingSelection, quantity: Int) throws
    func deposit(_ amount: Double)
    
    func item(forSelection selection: VendingSelection) -> VendingItem?
}


//Create object to represent a vending item that conforms to VendingItem
struct Item: VendingItem {
    let price: Double
    var quantity: Int
}

enum InventoryError: Error {
    case invalidResource
    case conversionFailure
    case invalidSelection
}

//Our plist converter doesn't need to hold onto any data
class PlistConverter {
    static func dictionary(fromFile name: String, ofType type: String) throws -> [String: AnyObject] {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            throw InventoryError.invalidResource
        }
        
        //Retrieve contents of the resource located at this path and convert that into a dictionary.
        //Without typcasting, dictionary will be of type NSDictionary but we need it to return a dictionary of type String to AnyObject so we downcast check using as?
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            throw InventoryError.conversionFailure
        }
        
        return dictionary
        
        
    }
}

//Convert plist into generic dictionary object
// After converting a plist into a generic dictionary object [String: AnyObject], we need to make an actual inventory out of it.
// The return type needs to be [VendingSelection: VendingItem] because that is the type of inventory in the VendingMachine protocol.
// Since VendingItem in the return type is a protocol, we can put in the value type anything that conforms to VendingItem, but since VendingSelection is an enum, is a concrete type and can't change.
class InventoryUnarchiver {
    static func vendingInventory(fromDictionary dictionary: [String: AnyObject]) throws -> [VendingSelection: VendingItem] {
        
        // Create empty dictionary to match the final one that we want to output
        var inventory: [VendingSelection: VendingItem] = [:]
        
        //Our source dictionary that we're passing into the method as an argument contains some values.  So lets iterate over the keys and values so that we can inspect and work with each pair.
        // (key, _) is a plist string
        for (key, value) in dictionary {
            // Now we have that next dictionary and cast to [String:Any]
            if let itemDictionary = value as? [String: Any], let price = itemDictionary["price"] as? Double, let quantity = itemDictionary["quantity"] as? Int {
                let item = Item(price: price, quantity: quantity)//use initializer to pass through price and quantity.  We want to adds this item along with the key back into inventory dictionary
                
                guard let selection = VendingSelection(rawValue: key) else { //selection is the (key, _) and item is the value (_, value)
                    throw InventoryError.invalidSelection
                }
                
                //Add updated (key, value) back to dictonary
                inventory.updateValue(item, forKey: selection)
            }
            
            
        }
        
        return inventory
    }
}

enum VendingMachineError: Error {
    case invalidSelection
    case outOfStock
    case insufficientFunds(required: Double)
}

class FoodVendingMachine: VendingMachine {
    let selection: [VendingSelection] = [.soda, .dietSoda, .chips, .cookie, .wrap, .sandwich, .candyBar, .popTart, .water, .fruitJuice, .sportsDrink, .gum]
    var inventory: [VendingSelection : VendingItem]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : VendingItem]){
        self.inventory = inventory
    }
    
    func vend(selection: VendingSelection, quantity: Int) throws {
        guard var item = inventory[selection] else {
            throw VendingMachineError.invalidSelection
        }
        
        guard item.quantity >= quantity else {
            throw VendingMachineError.outOfStock
        }
        
        let totalPrice = item.price * Double(quantity)
        
        if amountDeposited >= totalPrice {
            amountDeposited -= totalPrice //The money we have left
            
            item.quantity -= quantity //Deduct the quantity being purchase from the items quantity in inventory.  the rhs quantity is the argument to the method. Only modifying the quantity value on that struct here. below we update the inventory
            
            inventory.updateValue(item, forKey: selection)
         
        // If amount deposited is less than totalPrice
        } else {
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.insufficientFunds(required: amountRequired) //We use the insufficientFunds required associated value to pass in amountRequired
        }
        
    }
    
    func deposit(_ amount: Double) {
    }
    
    func item(forSelection selection: VendingSelection) -> VendingItem? {
        return inventory[selection]
    }
        
}


/*
 when a user selects an item, we need to make sure it is a valid one, then check if it is in stock, then make sure they have enough cash to buy. These are all cases where an error can occor
 */









