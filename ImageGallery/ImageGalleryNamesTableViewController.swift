//
//  ImageGalleryNamesViewController.swift
//  ImageGallery
//
//  Created by Пермяков Андрей on 2/12/19.
//  Copyright © 2019 Пермяков Андрей. All rights reserved.
//

import UIKit

class ImageGalleryNamesTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImageGalleryNamesTableViewController.renameImageGallery))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        tableView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    private var indexOfCurrentlyRenamingRow: IndexPath? = nil
    
    @objc func renameImageGallery(recognizer: UITapGestureRecognizer) {
        let touchPoint = recognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: touchPoint), indexPath.section == 0 {
            indexOfCurrentlyRenamingRow = indexPath
            if let cell = tableView.cellForRow(at: indexPath) as? GalleryNameTableViewCell {
                let oldText = cell.textField.text ?? ""
                cell.textField.isUserInteractionEnabled = true
                cell.textField.becomeFirstResponder()
                cell.resignationHandler = { [weak self, unowned cell] in
                    if let newText = cell.textField.text, newText != oldText {
                        self?.imageGalleries[newText] = self!.imageGalleries[oldText]
                        self?.imageGalleries[oldText] = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source

    var imageGalleryNames = ["one", "two", "three"]
    var imageGalleries: [String: Gallery] = [:]
    var recentlyDeletedImageGalleryNames = [String]()
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return imageGalleryNames.count
        case 1:
            return recentlyDeletedImageGalleryNames.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Galleries"
        case 1:
            return "Recently Deleted"
        default:
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if let textFieldCell = cell as? GalleryNameTableViewCell {
            textFieldCell.configureTextField(imageGalleryNames[indexPath.item])
        }
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    @IBAction func createGallery(_ sender: UIBarButtonItem) {
        imageGalleryNames.append("Untitled".madeUnique(withRespectTo: imageGalleryNames))
        tableView.insertRows(at: [IndexPath(row: imageGalleryNames.count - 1, section: 0)], with: .left)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let section = indexPath.section
            switch section {
            case 0:
                tableView.performBatchUpdates({
                    recentlyDeletedImageGalleryNames.append(imageGalleryNames.remove(at: indexPath.item))
                    tableView.moveRow(at: indexPath, to: IndexPath(row: recentlyDeletedImageGalleryNames.count - 1, section: 1))
                })
            case 1:
                tableView.performBatchUpdates({
                    recentlyDeletedImageGalleryNames.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                })
            default:
                break
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 {
            let contextualAction = UIContextualAction(style: .normal, title: "Undelete", handler: { (action, view, nil) in
                tableView.performBatchUpdates({
                    self.imageGalleryNames.append(self.recentlyDeletedImageGalleryNames.remove(at: indexPath.item))
                    tableView.moveRow(at: indexPath, to: IndexPath(row: self.imageGalleryNames.count - 1, section: 0))
                    tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                })
            })
            contextualAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            let swipeAction = UISwipeActionsConfiguration(actions: [contextualAction])
            swipeAction.performsFirstActionWithFullSwipe = true
            return swipeAction
        } else {
            return nil
        }
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "ShowGallery":
                    if let cell = sender as? GalleryNameTableViewCell, let destinationVC = segue.destination as? UINavigationController
                        {
                        if let collectionVC = destinationVC.visibleViewController as? ImageGalleryCollectionViewController, let text = cell.textField.text {
                            if let gallery = imageGalleries[text] {
                                collectionVC.imageURLs = gallery.imageURLs
                                collectionVC.imageAspectRatio = gallery.imageAspectRatios
                            }
                        }
                }
                default: break
            }
        }
    }
    
    private var selectedIndexPath: IndexPath?
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if selectedIndexPath != nil {
            if let navigationVC = splitViewController?.viewControllers[1] as? UINavigationController,
                let collectionVC = navigationVC.visibleViewController as? ImageGalleryCollectionViewController {
                if let text = (tableView.cellForRow(at: selectedIndexPath!) as? GalleryNameTableViewCell)?.textField.text {
                    let gallery = Gallery(collectionVC.imageURLs, collectionVC.imageAspectRatio)
                    imageGalleries[text] = gallery
                    print(imageGalleries)
                }
            }
        }
        selectedIndexPath = indexPath
        return indexPath
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            return indexPath.section == 0
        } else {
            return false
        }
    }
}
