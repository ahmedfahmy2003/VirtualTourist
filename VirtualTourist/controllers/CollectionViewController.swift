//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Ahmed Fahmy on 20/02/2019.
//  Copyright © 2019 Mohtaref. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData
import Kingfisher


class CollectionViewController: UIViewController, MKMapViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,NSFetchedResultsControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newImages: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    var dataController:DataController!
    var pin: Pin!
    var lat: Double!
    var lon: Double!
    
    var page: Int = 1
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var insertedIndexPaths : [IndexPath]!
    var deletedIndexPaths : [IndexPath]!
    var updatedIndexPaths : [IndexPath]!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.isUserInteractionEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        self.displayLoadingView(false)
        setUpCoreData()
        
        guard let pin = pin else {return}
        showSelectedPin()
        let photosCount = pin.photos?.count
        if photosCount! == 0{
            fetchNewImages()
        }
        statusLabel.text = ""
        
    }
    private func updateStatus(_ text: String) {
        self.performUIUpdatesOnMain {
            self.statusLabel.text = text
        }
    }
    func setUpCoreData(){
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    @IBAction func newImagesPressed(_ sender: Any) {
        page += 1
        fetchNewImages()
    }
    private func fetchNewImages() {
        self.displayLoadingView(true)
        API.getFlickerImagesUrls(lat: pin.latitude, lon: pin.longitude, page: page) {
            (flickrNewImagesUrls) in
            for photoUrl in flickrNewImagesUrls {
                
                let imageURL = URL(string: photoUrl)
                if let imageData = try? Data(contentsOf: imageURL!) {
                    if let image = UIImage(data: imageData){
                        let data = image.pngData()
                        
                        let photo = Photo(context: DataController.shared.viewContext)
                        photo.img = data
                        photo.creationDate = Date()
                        photo.url = photoUrl
                        photo.pin = self.pin
                        try? DataController.shared.viewContext.save()
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                        
                }
            }
            
        }
        self.displayLoadingView(false)
    }
    func showSelectedPin(){
        let annotation = MKPointAnnotation()
        if let showPin = self.pin{
            annotation.coordinate.latitude = showPin.latitude
            annotation.coordinate.longitude = showPin.longitude
            mapView.addAnnotation(annotation)
            mapView.setCenter(annotation.coordinate, animated: true)
        }else{
            showAlert(title: "Invalid Pin", message: "Pin coordinates is wrong")
        }
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.sections?[section].numberOfObjects
        {return count}
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "viewCell", for: indexPath) as! CollectionViewCell
        cell.flickrPhoto.image = UIImage(data: photo.img!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let deletedPhoto = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(deletedPhoto)
        try! self.dataController.viewContext.save()
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = []
        deletedIndexPaths = []
        updatedIndexPaths = []
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(newIndexPath!)
            break
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
}


extension CollectionViewController {
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            self.showAlert(title: "Invalid Link", message: "No link Available")
        }
}
    func displayLoadingView(_ isLoading: Bool) {
        DispatchQueue.main.async {
            self.loadingView.isHidden = !isLoading
            if isLoading {
                self.loadingActivityIndicator.startAnimating()
            } else {
                self.loadingActivityIndicator.stopAnimating()
            }
        }
    }
}
