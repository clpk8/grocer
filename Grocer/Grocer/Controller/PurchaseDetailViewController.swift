//
//  PurchaseDetailViewController.swift
//  Grocer
//
//  Created by linChunbin on 11/8/18.
//  Copyright © 2018 it4500. All rights reserved.
//

import UIKit

class PurchaseDetailViewController: UIViewController {
    var purchase:Purchase?
    var user:User?
    
    @IBOutlet weak var receiptImage: UIImageView!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    
    @IBOutlet weak var purchaserImage: UIImageView!
    @IBOutlet weak var itemsTableView: UITableView!
    
    var selectedItems = [Item]()
    var items = [Item]()
    override func viewDidLoad() {
        
        itemsTableView?.allowsMultipleSelection = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateField.text = dateFormatter.string(from: (purchase?.date)!)
        receiptImage.image = UIImage(data: (purchase?.receipt)!)
        titleField.text = purchase?.title ?? ""
        if let imageData = purchase?.getPurchaser()?.getPicture(){
            purchaserImage.image = UIImage(data: imageData)
        }
        else{
            purchaserImage.image = UIImage(named: "ProfileImage")
        }
        descriptionField.text = purchase?.getPurchaseDescription() ?? ""
        
        if let tempItems = purchase?.getItems(){
            items = tempItems
        }
        getItems()
        for item in items {
            if selectedItems.contains(item) {
                let index = items.firstIndex(of: item)
                if let index = index {
                    itemsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.none)
                }
            }
        }

        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    func getItems(){
        if let selectedItems = purchase?.getItems(){
            self.selectedItems = selectedItems
        }
        
        for item in selectedItems{
            if let user = user{
                if !item.getUsers()!.contains(user){
                    selectedItems.remove(at: selectedItems.firstIndex(of: item)!)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectedIndexes = itemsTableView.indexPathsForSelectedRows{
            for index in selectedIndexes{
                if (!selectedItems.contains(items[index.row])) {
                    selectedItems.append(items[index.row])
                }
            }
        }
        
        if segue.identifier == "detailToMyPurchase",
            let destination = segue.destination as? MyPurchaseViewController{
            destination.myItems = selectedItems
            destination.user = user
            destination.purchase = purchase
        }
        
    }

}

extension PurchaseDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell")!
        cell.textLabel?.text = items[indexPath.row].name
        cell.detailTextLabel?.text = String(items[indexPath.row].price)
        return cell
    }
    
}

