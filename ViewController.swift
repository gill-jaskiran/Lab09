//
//  ViewController.swift
//  lab09
//
//  Created by Jaskiran Gill on 2025-03-19.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var RouteButton: UIButton!
    
    var locations: [CLLocationCoordinate2D] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Map.delegate = self
        
        // addding points
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapClicked(_:)))
        Map.addGestureRecognizer(tapGesture)
    }

    // removing the point wheb clicked
    @objc func mapClicked(_ sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: Map)
        let coordinate = Map.convert(touchPoint, toCoordinateFrom: Map)
        
        // seeing if a point is neear
        if let index = locations.firstIndex(where: { pointIsNear($0, coordinate) }) {
            locations.remove(at: index)
            createAgainMap()
            return
        }

        // new pooint added - max 3
        if locations.count < 3 {
            locations.append(coordinate)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            Map.addAnnotation(annotation)
        }

        // Adrawing triangle after 3
        if locations.count == 3 {
            drawTriangle()
        }
    }

    // checking if point is tapped again near same location
    func pointIsNear(_ point1: CLLocationCoordinate2D, _ point2: CLLocationCoordinate2D) -> Bool {
        let tolerance: Double = 0.07
        return abs(point1.latitude - point2.latitude) < tolerance && abs(point1.longitude - point2.longitude) < tolerance
    }

    // drawing triangle
    func drawTriangle() {
        let polygon = MKPolygon(coordinates: locations, count: locations.count)
        Map.addOverlay(polygon)
        
        // distance added between each point
        for i in 0..<3 {
            let start = locations[i]
            let end = locations[(i + 1) % 3]
            let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude)) / 1000
            
            let midPoint = CLLocationCoordinate2D(
                latitude: (start.latitude + end.latitude) / 2,
                longitude: (start.longitude + end.longitude) / 2
            )
            
            let label = MKPointAnnotation()
            label.coordinate = midPoint
            label.title = String(format: "%.2f km", distance)
            Map.addAnnotation(label)
        }
    }

    // creating map again
    func createAgainMap() {
        Map.removeOverlays(Map.overlays)
        Map.removeAnnotations(Map.annotations)
        
        for location in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            Map.addAnnotation(annotation)
        }

        // if 3 points selected draw triangle
        if locations.count == 3 {
            drawTriangle()
        }
    }

    // Route rendering
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 2
            return renderer
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }

    // button for route
    @IBAction func showRouteTapped(_ sender: UIButton) {
        showRoute()
        
        
    }

    // showing the route between the points
    func showRoute() {
        guard locations.count == 3 else {
            return
        }

        let request = MKDirections.Request()
        request.transportType = .automobile
        
        var waypoints = locations
        waypoints.append(locations.first!)
        var previousRoutePolyline: MKPolyline?

        // route between each pair of points (A -> B, B -> C, C -> A)
        for i in 0..<waypoints.count - 1 {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i + 1]))

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else { return }
                
                // Remove the previous route and add the new one
                if let previousPolyline = previousRoutePolyline {
                    self.Map.removeOverlay(previousPolyline)
                }
                self.Map.addOverlay(route.polyline)
                previousRoutePolyline = route.polyline
            }
        }
    }
}

