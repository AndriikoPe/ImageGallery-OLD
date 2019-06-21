//
//  ImageGalleryViewController.swift
//  ImageGallery
//
//  Created by Пермяков Андрей on 2/12/19.
//  Copyright © 2019 Пермяков Андрей. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDelegateFlowLayout {
    
    var imageGallery: Gallery? {
        get {
            if imageURLs.count != 0 {
                return Gallery(imageURLs, imageAspectRatio)
            } 
            return nil
        }
        set {
            if let gallery = newValue {
                imageURLs = gallery.imageURLs
                imageAspectRatio = gallery.imageAspectRatios
            }
        }
    }
    
    var imageURLs = [URL]()
    var imageAspectRatio = [Float]() //  height / width

    private var cellWidth: CGFloat = 400
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ImageGalleryCollectionViewController.resizeCells))
        collectionView.addGestureRecognizer(pinchGestureRecognizer)
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let url = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Untitled.json") {
            if let jsonData = try? Data(contentsOf: url) {
                imageGallery = Gallery(json: jsonData)
            }
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if let json = imageGallery?.json {
            if let url = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
                ).appendingPathComponent("Untitled.json") {
                do {
                    try json.write(to: url)
                    print("saved successfully")
                } catch let error {
                    print("couldn't save \(error)")
                }
            }
        }
    }
    
    //MARK: Gestures
    
    @objc private func resizeCells(recognizer: UIPinchGestureRecognizer) {
        if imageURLs.count > 0 {
            if recognizer.state == .began || recognizer.state == .changed {
                let scale = recognizer.scale
                if scale < 1 {
                    cellWidth -= scale * 4 // (* 4) just to make it faster & nicer
                } else {
                    cellWidth += scale * 4
                }
                recognizer.scale = 1.0
                flowLayout?.invalidateLayout()
            }
        }
    }
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: collectionView.bounds.height)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imageVC = segue.destination.contents as? FullImageViewController {
            imageVC.imageURL = sender as? URL
        }
    }
 

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath)
        if let imageCell = cell as? ImageGalleryCollectionViewCell {
            imageCell.imageView.image = nil
            imageCell.spinner.startAnimating()
            let url = imageURLs[indexPath.item]
            DispatchQueue.global(qos: .userInitiated).async {
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents {
                        let image = UIImage(data: imageData)
                        let sizedImage = image?.resize(width: imageCell.bounds.width, height: CGFloat(self.imageAspectRatio[indexPath.item]) * imageCell.bounds.width)
                        imageCell.imageView.image = sizedImage
                    } else {
                        imageCell.imageView.backgroundColor = #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
                    }
                    imageCell.spinner.stopAnimating()
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if let image = (collectionView.cellForItem(at: indexPath) as? ImageGalleryCollectionViewCell)?.imageView.image {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = image
            return [dragItem]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) ||  session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy,  intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: imageURLs.count, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                if (item.dragItem.localObject as? UIImage) != nil {
                    collectionView.performBatchUpdates({
                        let movedURL = self.imageURLs.remove(at: sourceIndexPath.item)
                        self.imageURLs.insert(movedURL, at: destinationIndexPath.item)
                        let movedAspectRatio = self.imageAspectRatio.remove(at: sourceIndexPath.item)
                        self.imageAspectRatio.insert(movedAspectRatio, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                        
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let image = provider as? UIImage {
                        let width = image.size.width
                        let height = image.size.height
                        self.imageAspectRatio.insert(Float(height / width), at: destinationIndexPath.item)
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    if let url = provider as? URL {
                        let correctURL = url.imageURL
                        self.imageURLs.insert(correctURL, at: destinationIndexPath.item)
                        DispatchQueue.main.async {
                            collectionView.insertItems(at: [destinationIndexPath])
                        }
                    }
                }
            }
        }
    }
    
    
    
    

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let url = imageURLs[indexPath.item]
        self.performSegue(withIdentifier: "showFullImage", sender: url)
    }
    
    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}


extension UIImage {
    func resize(width: CGFloat, height: CGFloat) -> UIImage? {
        let size = CGSize(width: width, height: height)
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
