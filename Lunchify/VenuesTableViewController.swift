//
//  VenuesTableViewController.swift
//  Lunchify
//
//  Created by Sallar Kaboli on 11/22/15.
//  Copyright © 2015 Sallar Kaboli. All rights reserved.
//

import UIKit
import CoreLocation
import JGProgressHUD

class VenuesTableViewController: UITableViewController, CLLocationManagerDelegate, UISearchResultsUpdating {
    
    var venues: [Venue] = []
    var filteredVenues: [Venue] = []
    var resultSearchController: UISearchController?
    var location: CLLocation?
    let locationManager = CLLocationManager()
    let HUD = JGProgressHUD(style: .Dark)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        
        // Location
        locationManager.delegate = self
        locationManager.distanceFilter = 500
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Search bar
        definesPresentationContext = true
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.searchBarStyle = .Minimal
            
            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
    }

    func configureView() {
        tableView.rowHeight = 64
        let image = UIImage(named: "logo")
        self.navigationItem.titleView = UIImageView(image: image)
        
        // Progress
        HUD.textLabel.text = "Loading..."
        HUD.showInView(self.navigationController?.view)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Load Venues
    func loadVenues() {
        let venues = VenuesService()
        
        // Get venues
        venues.getVenues(self.location!) { retrievedVenues in
            if let venues = retrievedVenues {
                
                // Go back to main process
                dispatch_async(dispatch_get_main_queue()) {
                    self.venues = venues.allVenues
                    self.filteredVenues = self.venues
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    self.HUD.dismiss()
                }
                
            } else {
                print("Fetch failed")
            }
        }
    }
    
    @IBAction func refreshVenues(sender: UIRefreshControl) {
        loadVenues()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredVenues.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VenueCell", forIndexPath: indexPath) as! VenueTableViewCell
        let venue = self.filteredVenues[indexPath.row]

        // Configure the cell...
        cell.venueTitleLabel?.text = venue.name
        cell.venueAddressLabel?.text = venue.address
        
        if let location = self.location {
            cell.venueDistanceLabel?.text = venue.distanceFromLocation(location)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowVenue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let venue = filteredVenues[indexPath.row]
                let controller = (segue.destinationViewController as! MenuViewController)
                controller.venue = venue
            }
        }
    }
    
    // MARK: - Location
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.location == nil {
            self.location = locations.first
            self.loadVenues()
        } else {
            self.location = locations.first
        }
    }
    
    // MARK: - Search
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filteredVenues = searchText.isEmpty ? venues : venues.filter({(venue: Venue) -> Bool in
                return venue.name!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
            })
            
            tableView.reloadData()
        }
    }

}
