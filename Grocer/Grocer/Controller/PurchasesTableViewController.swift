//
//  PurchasesTableViewController.swift
//  Grocer
//
//  Created by linChunbin on 11/1/18.
//  Copyright © 2018 it4500. All rights reserved.
//

import UIKit
import CoreData

class PurchasesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var tableView: UITableView!
    var user: User?
    var purchases: [Purchase] = []
    var rawPurchases:[Purchase] = []
    var pastPurchases:[Purchase] = []
    var activePurchases:[Purchase] = []
    var filteredPurchases = [Purchase]()
    var filteredActive = [Purchase]()
    var filteredPast = [Purchase]()
    let searchController = UISearchController(searchResultsController: nil)
    let imagePicker = UIImagePickerController()
    var imageForReceipt: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        filteredPurchases = purchases
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        for purchase in filteredPurchases {
            if (!isPurchaseActive(purchase: purchase)){
                pastPurchases.append(purchase)
                filteredPast.append(purchase)
            }
            else{
                activePurchases.append(purchase)
                filteredActive.append(purchase)
            }
        }
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        refreshControl.tintColor = UIColor.red
        tableView.refreshControl = refreshControl
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchPurchases()
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return filteredActive.count
        case 1:
            return filteredPast.count
        default:
            return filteredPurchases.count
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "purchaseCell", for: indexPath)
        if (indexPath.section == 0){
            if let cell = cell as? PurchaseTableViewCell{
                let purchase = filteredActive[indexPath.row]
                
                populatePurchaseCell(purchase: purchase, cell: cell)
            }
        }
        else if(indexPath.section == 1){
            if let cell = cell as? PurchaseTableViewCell{
                let purchase = filteredPast[indexPath.row]
                
                populatePurchaseCell(purchase: purchase, cell: cell)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0){
            return "Active Purchase"
        }
        if (section == 1){
            return "Past Purchase"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return 90
        default:
            return 120
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "purchaseDetailSegue",
            let destination = segue.destination as? PurchaseDetailViewController,
            let row = tableView.indexPathForSelectedRow?.row {
            destination.user = user
            if (tableView.indexPathForSelectedRow?.section == 0){
                destination.purchase = filteredActive[row]
            }
            else if (tableView.indexPathForSelectedRow?.section == 1){
                destination.purchase = filteredPast[row]
            }
            tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
        }
        if segue.identifier == "addSegue",
            let destination = segue.destination as? AddPurchaseViewController {
            destination.purchaser = user
            destination.receiptImage = imageForReceipt
            
        }
    }
    
    func populatePurchaseCell(purchase:Purchase, cell: PurchaseTableViewCell){
        
        cell.purchaseLabel.text = purchase.title
        cell.purchaseDateLabel.text = formatDate(date: purchase.date!)
        if let receipt = purchase.receipt,
            let receiptImage = UIImage(data: receipt) {
            cell.purchaseImage.image = receiptImage
        } else {
            cell.purchaseImage.image = UIImage(named: "ProfileImage")
        }
    }
    
    
    func isPurchaseActive(purchase: Purchase) -> Bool {
        var totalPayments = 0.0;
        var totalPrice = 0.0;
        if let payments = purchase.getPayments() {
            for payment in payments {
                totalPayments += payment.amount
            }
        }
        
        if let items = purchase.getItems() {
            for item in items {
                totalPrice += item.price
            }
        }
        
        return totalPayments != totalPrice
    }
    
    func formatDate(date: Date) -> String {
        let today = Date(timeIntervalSinceNow: 0)
        let yesterday = Date(timeIntervalSinceNow: -60*60*24)
        let dayBeforeYesterday = Date(timeIntervalSinceNow: -60*60*24*2)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if date >= today {
            return "Something Went Wrong"
        } else if date >= yesterday {
            return "Today"
        } else if date >= dayBeforeYesterday {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: date)
        }
    }
    func updateSearchResults(for searchController: UISearchController) {
        // If we haven't typed anything into the search bar then do not filter the results
        if searchController.searchBar.text! == "" {
            filteredPurchases = purchases
            filteredActive = activePurchases
            filteredPast = pastPurchases
        } else {
            filteredActive = activePurchases.filter { $0.title!.lowercased().contains(searchController.searchBar.text!.lowercased()) }
            filteredPast = pastPurchases.filter { $0.title!.lowercased().contains(searchController.searchBar.text!.lowercased()) }
        }
        
        self.tableView.reloadData()
    }
    
    func fetchPurchases(){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Purchase> = Purchase.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        do {
            rawPurchases = try managedContext.fetch(fetchRequest)
            tableView.reloadData()
        } catch {
            presentMessage(message: "An error occurred fetching: \(error)")
        }
        
        purchases = filterPurchasesByUser()
        pastPurchases.removeAll()
        activePurchases.removeAll()
        filteredPurchases.removeAll()
        filteredPast.removeAll()
        filteredActive.removeAll()
        
        filteredPurchases = purchases
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        for purchase in filteredPurchases {
            if (!isPurchaseActive(purchase: purchase)){
                pastPurchases.append(purchase)
                filteredPast.append(purchase)
            }
            else{
                activePurchases.append(purchase)
                filteredActive.append(purchase)
            }
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        fetchPurchases()
        
        refreshControl.endRefreshing()
    }
    
    func presentMessage(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add a Receipt Photo", message: "How do you want to upload the picture?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { action in
            self.takePhotoWithCamera()
        }))
                                      
                                      
                                      
        alert.addAction(UIAlertAction(title: "Use Existing Photo", style: .default, handler: { action in
            self.getPhotoFromLibrary()
        }))
        self.present(alert, animated: true)
        
    }
    func takePhotoWithCamera() {
        if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            let alertController = UIAlertController(title: "No Camera", message: "The device has no camera.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func getPhotoFromLibrary() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageForReceipt = pickedImage
            performSegue(withIdentifier: "addSegue", sender: self)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func filterPurchasesByUser() -> [Purchase]{
        var tempPurchase: [Purchase] = []
        if let user = user{
            
            for purchase in rawPurchases{
                if let purchaser = purchase.getPurchaser(){
                    if purchaser.isEqual(user){
                        tempPurchase.append(purchase)
                    }
                    
                }
                if let recipients = purchase.getRecipients(){
                    
                    if recipients.contains(user){
                        tempPurchase.append(purchase)
                    }
                }
                
            }
        }
        return tempPurchase
    }
}

