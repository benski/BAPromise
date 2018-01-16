//
//  PTRViewController.swift
//  iOS
//
//  Created by Ben Allison on 1/15/18.
//  Copyright © 2018 Ben Allison. All rights reserved.
//

import UIKit

@objc class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // views
    let refreshControl = UIRefreshControl()
    let tableView  = UITableView()
    let cellReuseIdentifier = "cell"
    
    // models
    var modelLoadPromise : Promise<AnyObject>?
    var model : Array<Dictionary<String, Any>>?
    var imageRequests = Dictionary<IndexPath, BACancelToken>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.frame = self.view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        self.view.addSubview(tableView)
        
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        
        tableView.addSubview(refreshControl)
    }

    func getData(request : URLRequest) -> Promise<NSData> {
        let promise = Promise<NSData>()
        let defaultSession = URLSession(configuration: .default)
        let dataTask = defaultSession.dataTask(with: request) { data, response, error in
            if let error = error {
                promise.rejectWithError(error)
            } else if let data = data {
                promise.fulfill(with: data as NSData)
            } else {
                promise.fulfill()
            }
        }
        dataTask.resume()
        promise.cancelled({
            dataTask.cancel()
        })
        return promise
    }
    
    @discardableResult func loadModel() -> Promise<AnyObject>? {
        if modelLoadPromise != nil {
            return modelLoadPromise
        }
        
        var request = URLRequest(url: URL(string: "https://www.strava.com/api/v3/clubs/108605/activities?per_page=100")!)
        request.setValue("Bearer 51b10c6bd4e545c9e69b6d01f23f9f7df215f335", forHTTPHeaderField: "Authorization")
        modelLoadPromise = getData(request: request).then { data -> Any? in
                if let data = data  {
                    do {
                        return try JSONSerialization.jsonObject(with: data as Data)
                    } catch let error as NSError {
                        return error
                    }
                } else {
                    return nil
                }
                }.then({ obj -> Any? in
                    self.tableView.backgroundColor = .clear
                    self.model = obj as? Array<Dictionary<String, Any>>
                    self.tableView.reloadData()
                    return obj
                }, rejected: { (error) in
                    self.tableView.backgroundColor = .red
                    self.model = [["name": error.localizedDescription]];
                    self.tableView.reloadData()
                    return error
                })
            return modelLoadPromise
    }
    
    @objc private func refreshData(_ sender: Any) {
        modelLoadPromise?.cancel()
        modelLoadPromise = nil
        loadModel()?.finally {
            self.refreshControl.endRefreshing()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier:cellReuseIdentifier) as UITableViewCell!
        cell.imageView?.image = nil
        
        if let singleModel = model?[indexPath.row] {
            if let text = singleModel["name"] as? String {
                cell.textLabel?.text = text
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let singleModel = model?[indexPath.row] {
            if let athlete = singleModel["athlete"] as? Dictionary<String, Any>,
                let url = athlete["profile_medium"] as? String  {
                imageRequests[indexPath] = getData(request: URLRequest(url: URL(string: url)!)).done( { (data : NSData?) -> Void in
                    if let data = data {
                        let image = UIImage(data: data as Data)
                        cell.imageView?.image = image
                        cell.setNeedsLayout()
                    }
                }, finally: {
                    self.imageRequests[indexPath] = nil
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.imageRequests[indexPath]?.cancel()
        self.imageRequests[indexPath] = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        modelLoadPromise?.cancel()
        modelLoadPromise = nil
        model = nil
    }

}
