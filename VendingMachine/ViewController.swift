//
//  ViewController.swift
//  VendingMachine
//
//  Created by Pasan Premaratne on 12/1/16.
//  Copyright © 2016 Treehouse Island, Inc. All rights reserved.
//
/*
 Helpful Notes
 - A collectionView stores and displays data using indexes and it's often store in a indexPath argument
 - When we tap on an item, we need to save it someplace to do something with it so create new stored property as optional VendingSelection
 - Once we know what a users selection is, we can build the func to build
 - When we selection an item in the view, the item gets assigned to the currentSelection stored property.  So now we know which item the user wants.
 - Our users purchase an item when they press the purchase button so we need to create an action
 - A convenience method does nothing more than wrap a function around an accessor we can already use.   This just gives more context to developers about the code
 - An alert view is represented by the class UIAlertcontroller
 - Create an alert action with UIAlertACtion.  The handler: takes a function that has an argument of UIAlertAction and returns void <#T##((UIAlertAction) -> Void)?##((UIAlertAction) -> Void)?##(UIAlertAction) -> Void#>)
 */

import UIKit

fileprivate let reuseIdentifier = "vendingItem"
fileprivate let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    
    //add stored property to store our vendingMachine and set the type to be the protocol type rather than the class so we can switch out vending machines in the future
    let vendingMachine: VendingMachine
    var currentSelection: VendingSelection? //Optional because at launch it will be nil
    
    //since the vendingMachine property doesn't have an initial value, we need to initialize it via init method
    //Use built in view controller classed built-in initializer and it is REQUIRED
    required init?(coder aDecoder: NSCoder) {
        do {
            //Convert plist into dictionary
            let dictionary = try PlistConverter.dictionary(fromFile: "VendingInventory", ofType: "plist")
            // Once we have dictionary, create an inventory
            let inventory = try InventoryUnarchiver.vendingInventory(fromDictionary: dictionary)
            //Use inventory to initialize the vendingMachine stored property
            self.vendingMachine = FoodVendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCollectionViewCells()
        
        updateDisplayWith(balance: vendingMachine.amountDeposited, totalPrice: 0, itemPrice: 0, itemQuantity: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup

    func setupCollectionViewCells() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        let padding: CGFloat = 10
        let itemWidth = screenWidth/3 - padding
        let itemHeight = screenWidth/3 - padding
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Vending Machine
    
    //As a user, when I click the purchase button, this happens.
    @IBAction func purchase() {
        if let currentSelection = currentSelection { // 1st. Check if currentSelection is nil
            do {
                try vendingMachine.vend(selection: currentSelection, quantity: Int(quantityStepper.value))
                updateDisplayWith(balance: vendingMachine.amountDeposited, totalPrice: 0.00, itemPrice: 0, itemQuantity: 1)
                
            } catch VendingMachineError.outOfStock {
                showAlertWith(title: "Out of Stock", message: "This item is unavailable.  Please make another selection")
                
            } catch VendingMachineError.invalidSelection {
                showAlertWith(title: "Invalid Selection", message: "Please make another selection")
                
            } catch VendingMachineError.insufficientFunds(let required) {
                let message = "You need $\(required) to complete the transaction"
                showAlertWith(title: "Insufficient Funds", message: message)
                
            } catch let error {
                fatalError("\(error)")
            }
            
            //Deselect cell highlight after successful purchase()
            if let indexPath = collectionView.indexPathsForSelectedItems?.first { //I'm asking collectionView which cells are selected here
                collectionView.deselectItem(at: indexPath, animated: true)
                updateCell(having: indexPath, selected: false)
            }
        } else {
            // FIXME: Alert user to no selection
        }
        
    }
    
    //This method accepts a series of optional arguments for each label.text
    func updateDisplayWith(balance: Double? = nil, totalPrice: Double? = nil, itemPrice: Double? = nil, itemQuantity: Int? = nil) {
        
        
        if let balanceValue = balance {
            balanceLabel.text = "\(balanceValue)"
        }
        
        if let totalValue = totalPrice {
            totalLabel.text = "\(totalValue)"
        }
        
        if let priceValue = itemPrice {
            priceLabel.text = "$\(priceValue)"
        }
        
        if let quantityValue = itemQuantity {
            quantityLabel.text = "\(quantityValue)"
        }
        
    }
    
    
    func updateTotalPrice(for item: VendingItem) {
        //totalLabel.text = "$\(item.price * quantityStepper.value)"
        let totalPrice = item.price * quantityStepper.value
        updateDisplayWith(totalPrice: totalPrice)
    }
    
    // Add UIStepper control for quantity
    @IBAction func updateQuantity(_ sender: UIStepper) {
        let quantity = Int(quantityStepper.value)
        updateDisplayWith(itemQuantity: quantity)
        
        if let currentSelection = currentSelection, let item = vendingMachine.item(forSelection: currentSelection) {
            updateTotalPrice(for: item)
        }
    }
    
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        //Creation of alertConroller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        
        //Created dismissAlert so we can pass in function that matches handler type <#T##((UIAlertAction) -> Void)?##((UIAlertAction) -> Void)?##(UIAlertAction) -> Void#>
        let okAction = UIAlertAction(title: "Ok", style: .default, handler:  dismissAlert)
        
        //Add action to controller
        alertController.addAction(okAction)
        
        //Ask current viewController to show another view which is controlled by separate UIAlertController - on top of the current view.
        //We do that by using the present() method which takes a viewController to present.  This is used to present a modal interface.
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    func dismissAlert(sender: UIAlertAction) -> Void {
        //If we hit an error, we reset everything
        updateDisplayWith(balance: 0, totalPrice: 0, itemPrice: 0, itemQuantity: 1)
    }
    
    @IBAction func depositFunds() {
        vendingMachine.deposit(5.0)
        updateDisplayWith(balance: vendingMachine.amountDeposited)
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VendingItemCell else { fatalError() }
        
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    // Modeling the Vending Machine
    
    //When selecting an item, we execute this code
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
        
        quantityStepper.value = 1 //Everytime we select a new item, the quantity goes back to 1 be resetting the quantityStepper.value
        
        updateDisplayWith(totalPrice: 0, itemQuantity: 1)
        
        //[index.row] gives us the position we're tapping and we can use this index number again to look in the selection[array] and assign it to currentSelection
        currentSelection = vendingMachine.selection[indexPath.row]
        
        
        //Update item price and totalprice
        if let currentSelection = currentSelection, let item = vendingMachine.item(forSelection: currentSelection) {
            
            let totalPrice =  item.price * quantityStepper.value
            
            updateDisplayWith(totalPrice: totalPrice, itemPrice: item.price)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func updateCell(having indexPath: IndexPath, selected: Bool) {
        
        let selectedBackgroundColor = UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0)
        let defaultBackgroundColor = UIColor(red: 27/255.0, green: 32/255.0, blue: 36/255.0, alpha: 1.0)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? selectedBackgroundColor : defaultBackgroundColor
        }
    }
    
    
}

