//
//  MapViewController.swift
//  rwaclient
//
//  Created by Admin on 26.09.18.
//  Copyright © 2018 beryllium design. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension MapViewController {
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
            
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer()
    }
 }



extension MKMapView {
    open var currentZoomLevel: Int {
        let maxZoom: Double = 24
        let zoomScale = visibleMapRect.size.width / Double(frame.size.width)
        let zoomExponent = log2(zoomScale)
        return Int(maxZoom - ceil(zoomExponent))
    }
    
    open func setCenterCoordinate(_ centerCoordinate: CLLocationCoordinate2D,
                                  withZoomLevel zoomLevel: Int,
                                  animated: Bool) {
        let minZoomLevel = min(zoomLevel, 28)
        
        let span = coordinateSpan(centerCoordinate, andZoomLevel: minZoomLevel)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        
        setRegion(region, animated: animated)
    }
    
    func polygonFromRectangle(_ center:CLLocationCoordinate2D,_ width: Double,_ height: Double) -> MKPolygon
    {
        var rectCoordinates: [CLLocationCoordinate2D] = [];
        
        let w = calculateDestination(center, width/2, 90);
        let e = calculateDestination(center, width/2, 270);
        
        var nw:CLLocationCoordinate2D =  calculateDestination(w, height/2, 0) ;
        
        var sw:CLLocationCoordinate2D = (calculateDestination(w, height/2, 180) );
        if(sw.longitude < 0)
        {
            sw.longitude = sw.longitude + 360;
        }
        rectCoordinates.append(sw);
        
        if(nw.longitude < 0)
        {
            nw.longitude = nw.longitude + 360;
        }
        
        rectCoordinates.append(nw);
   
        
        var ne:CLLocationCoordinate2D = (calculateDestination(e, height/2, 0) );
        if(ne.longitude < 0)
        {
            ne.longitude = ne.longitude + 360;
        }
        
        rectCoordinates.append(ne);
        
        var se = (calculateDestination(e, height/2, 180) );
        if(se.longitude < 0)
        {
            se.longitude = se.longitude + 360;
        }
        
        rectCoordinates.append(se);
        let polygon = MKPolygon(coordinates: &rectCoordinates, count: rectCoordinates.count);
        return polygon;
        
    }
}

let MERCATOR_OFFSET: Double = 268435456 // swiftlint:disable:this identifier_name
let MERCATOR_RADIUS: Double = 85445659.44705395 // swiftlint:disable:this identifier_name
struct PixelSpace {
    public var x: Double // swiftlint:disable:this identifier_name
    public var y: Double // swiftlint:disable:this identifier_name
}

fileprivate extension MKMapView {
    func coordinateSpan(_ centerCoordinate: CLLocationCoordinate2D, andZoomLevel zoomLevel: Int) -> MKCoordinateSpan {
        let space = pixelSpace(fromLongitue: centerCoordinate.longitude, withLatitude: centerCoordinate.latitude)
        
        // determine the scale value from the zoom level
        let zoomExponent = 20 - zoomLevel
        let zoomScale = pow(2.0, Double(zoomExponent))
        
        // scale the map’s size in pixel space
        let mapSizeInPixels = self.bounds.size
        let scaledMapWidth = Double(mapSizeInPixels.width) * zoomScale
        let scaledMapHeight = Double(mapSizeInPixels.height) * zoomScale
        
        // figure out the position of the top-left pixel
        let topLeftPixelX = space.x - (scaledMapWidth / 2)
        let topLeftPixelY = space.y - (scaledMapHeight / 2)
        
        var minSpace = space
        minSpace.x = topLeftPixelX
        minSpace.y = topLeftPixelY
        
        var maxSpace = space
        maxSpace.x += scaledMapWidth
        maxSpace.y += scaledMapHeight
        
        // find delta between left and right longitudes
        let minLongitude = coordinate(fromPixelSpace: minSpace).longitude
        let maxLongitude = coordinate(fromPixelSpace: maxSpace).longitude
        let longitudeDelta = maxLongitude - minLongitude
        
        // find delta between top and bottom latitudes
        let minLatitude = coordinate(fromPixelSpace: minSpace).latitude
        let maxLatitude = coordinate(fromPixelSpace: maxSpace).latitude
        let latitudeDelta = -1 * (maxLatitude - minLatitude)
        
        return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
    
    func pixelSpace(fromLongitue longitude: Double, withLatitude latitude: Double) -> PixelSpace {
        let x = round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * Double.pi / 180.0)
        let y = round(MERCATOR_OFFSET - MERCATOR_RADIUS * log((1 + sin(latitude * Double.pi / 180.0)) / (1 - sin(latitude * Double.pi / 180.0))) / 2.0) // swiftlint:disable:this line_length
        return PixelSpace(x: x, y: y)
    }
    
    func coordinate(fromPixelSpace pixelSpace: PixelSpace) -> CLLocationCoordinate2D {
        let longitude = ((round(pixelSpace.x) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / Double.pi
        let latitude = (Double.pi / 2.0 - 2.0 * atan(exp((round(pixelSpace.y) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / Double.pi // swiftlint:disable:this line_length
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class MapViewController: UIViewController, MKMapViewDelegate
{
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapView.delegate = self
        if(scenes.isEmpty) {
            mapView.setCenterCoordinate(hero.coordinates, withZoomLevel: 15, animated: true);
          }
        else {
            mapView.setCenterCoordinate(scenes[0].coordinates, withZoomLevel: 15, animated: true);
        }
        
        mapView.showsScale = true;
        mapView.showsUserLocation = true;
    }
    
    func drawRwaArea(area: RwaArea) {
        
        if(area.areaType == RWAAREATYPE_POLYGON) {
            let polygon = MKPolygon(coordinates: &area.corners!, count: (area.corners?.count)!);
            mapView.add(polygon);
        }
        
        if(area.areaType == RWAAREATYPE_RECTANGLE || area.areaType == RWAAREATYPE_SQUARE) {
            
            let polygon = mapView.polygonFromRectangle(area.coordinates, area.width, area.height)
            mapView.add(polygon);
        }
        
        if(area.areaType == RWAAREATYPE_CIRCLE) {
            
            let circle = MKCircle(center: area.coordinates, radius: area.radius);
            mapView.add(circle);
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewDidLoad();
        
        if(!scenes.isEmpty)
        {
            for scene in scenes
            {
                drawRwaArea(area: scene);
                
              //  let polygon = MKPolygon(coordinates: &locations, count: locations.count);
                
                
                for state in scene.states {
                    
                    if(state.type != RWASTATETYPE_FALLBACK && state.type != RWASTATETYPE_BACKGROUND) {
                        drawRwaArea(area: state);
                    }
                    
                    for asset in state.assets {
                        
                    }
                }
            }
        }
        
    }
 }
