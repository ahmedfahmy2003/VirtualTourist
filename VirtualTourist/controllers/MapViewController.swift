//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Ahmed Fahmy on 20/02/2019.
//  Copyright © 2019 Mohtaref. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class MapViewController: UIViewController , MKMapViewDelegate {
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    @IBOutlet weak var mapView: MKMapView!
    var pins = [Pin]()
    var dataController: DataController!
    var addedPin : Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadPins()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        for item in mapView.selectedAnnotations{
            mapView.deselectAnnotation(item, animated: false)
        }
    }

    func loadPins(){
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = DataController.shared.viewContext
        let resultPins = try! context.fetch(fetchRequest)
        
        
        var annotation = [MyPinAnnotation()]
        for pin in resultPins{
            let newAnnotation = MyPinAnnotation()
            newAnnotation.coordinate.latitude = pin.latitude
            newAnnotation.coordinate.longitude = pin.longitude
            annotation.append(newAnnotation)
        }
        mapView.addAnnotations(annotation)
       

    }
    
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        
        guard sender.state == UIGestureRecognizer.State.began else { return }
        
        let selectedLocation = sender.location(in: self.mapView)
        let selectedCoordinates = self.mapView.convert(selectedLocation, toCoordinateFrom: self.mapView)
        
        let annotation = MyPinAnnotation()
        annotation.coordinate = selectedCoordinates
        
        // save new pin in store
        let pin = Pin(context: DataController.shared.viewContext)
        pin.latitude = selectedCoordinates.latitude
        pin.longitude = selectedCoordinates.longitude
        try? DataController.shared.viewContext.save()
        
        // variable for sending to next view
        self.addedPin = pin
        
        mapView.addAnnotation(annotation)
    }
    
}



extension MapViewController {
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let context = DataController.shared.viewContext
        let resultPins = try! context.fetch(fetchRequest)
        for pin in resultPins{
            vc.lon = view.annotation!.coordinate.longitude
            vc.lat = view.annotation!.coordinate.latitude
            vc.dataController = dataController
            if pin.latitude == vc.lat && pin.longitude == vc.lon {
                vc.pin = pin
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    static func getPinByCoordination(pins:[Pin],coordinate:CLLocationCoordinate2D?) -> Pin?{
        guard let coordinate = coordinate else{
            return nil
        }
        for pin in pins{
            if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude {
                return pin
            }
        }
        return nil
    }
}

