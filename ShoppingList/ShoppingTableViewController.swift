//
//  ShoppingTableViewController.swift
//  ShoppingList
//
//  Created by Usuário Convidado on 23/03/19.
//  Copyright © 2019 FIAP. All rights reserved.
//

import UIKit
import Firebase

class ShoppingTableViewController: UITableViewController {

    let collection = "shoppingList"
    var firestoreListener: ListenerRegistration!
    var firestore: Firestore = {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        var firestore = Firestore.firestore()
        firestore.settings = settings
        return firestore
    }()
    
    var shoppingList: [ShoppingItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Auth.auth().currentUser?.displayName
        listItems()
        
        
    }
    
    func listItems(){
        // adicionar antes de .addsnapshot .whereField("authorID", isEqualTo: Auth.auth().currentUser!.uid).order(by: "quantity", descending: true)
        firestoreListener = firestore.collection(collection).addSnapshotListener(includeMetadataChanges: true){ (snapshot, error) in
            if error != nil {
                print(error!)
            }
            
            guard let snapshot = snapshot else {return}
            print("Total de mudanças: ", snapshot.documentChanges.count)
            
            if snapshot.metadata.isFromCache || snapshot.documentChanges.count > 0 {
                self.showItems(snapshot: snapshot)
                
            }
            
        }
    }
    
    func showItems(snapshot: QuerySnapshot){
        shoppingList.removeAll()
        for document in snapshot.documents{
            let data = document.data()
            if let name = data["name"] as? String, let quantity = data["quantity"] as? Int {
                let shoppingItem = ShoppingItem(name: name, quantity: quantity, id: document.documentID)
                shoppingList.append(shoppingItem)
            }
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return shoppingList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let shoppingItem = shoppingList[indexPath.row]
        cell.textLabel?.text = shoppingItem.name
        cell.detailTextLabel?.text = "\(shoppingItem.quantity)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = shoppingList[indexPath.row]
        addEdit(shoppingItem: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = shoppingList[indexPath.row]
            firestore.collection(collection).document(item.id).delete()
        }
    }

    @IBAction func add(_ sender: Any) {
        addEdit()
    }
    
    func addEdit(shoppingItem: ShoppingItem? = nil) {
        let title = shoppingItem == nil ? "Adicionar" : "Editar"
        let message = shoppingItem == nil ? "Adicionado" : "Editado"
        let alert = UIAlertController(title: title, message: "Digite abaixo os dados do item a ser \(message)", preferredStyle: .alert)
        
        alert.addTextField { (textfield) in
            textfield.placeholder = "Nome"
            textfield.text = shoppingItem?.name
        }
        alert.addTextField { (textfield) in
            textfield.placeholder = "Quantidade"
            textfield.keyboardType = .numberPad
            textfield.text = shoppingItem?.quantity.description
        }
        let addAction = UIAlertAction(title: title, style: .default) { (_) in
            guard let name = alert.textFields?.first?.text,
                  let quantity = alert.textFields?.last?.text,
                !name.isEmpty, !quantity.isEmpty else {return}
            
            var item = shoppingItem ?? ShoppingItem()
            item.name = name
            item.quantity = Int(quantity) ?? 1
            self.addItem(item)
        }
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    func addItem(_ item: ShoppingItem){
        let data: [String: Any] = [
            "name": item.name,
            "quantity": item.quantity,
            "authorID": Auth.auth().currentUser!.uid
        ]
        
        if item.id.isEmpty {
            //Criar
            firestore.collection(collection).addDocument(data: data) { (error) in
                if error != nil {
                    print(error!)
                }
            }
        } else {
            //Editar
            firestore.collection(collection).document(item.id).updateData(data) { (error) in
                if error != nil {
                    print(error!)
                }
            }
        }
    }
    

}
