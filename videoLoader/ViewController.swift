//
//  ViewController.swift
//  videoLoader
//
//  Created by Mac on 07.07.2018.
//  Copyright © 2018 testOrg. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, MediaWorkerDelegate {
    
    private enum States {
        case none
        case loading
        case loadingSuspend
        case playing
        case paused
    }
    
    var countOfCellDownload: [Int] = []
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet private var label: UILabel!
    @IBOutlet private var button: UIButton!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet var playerView: PlayerView?
 
    private var player: AVPlayer?
    private var playerObservation: NSKeyValueObservation?
    private var file: URL?
    private lazy var worker: MediaWorker = {
        let worker = MediaWorker()
        worker.delegate = self
        return worker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = ""
        checkState()
    }

    
    // MARK: - IBActions
    
    @IBAction func addButton(_ sender: Any) {
        let addCount = countOfCellDownload.count + 1
        countOfCellDownload.append(addCount)
        tableView.reloadData()
    }
    
    @IBAction private func onButtonClick(_ sender: UIButton) {
        if file == nil {
            if worker.isTaskRunning {
                worker.cancel { [weak self] in self?.checkState() }
            } else if worker.hasDataToResume {
                worker.resume()
                checkState()
            } else {
                load()
                checkState()
            }
            return
        }
        
        if let time = player?.currentTime(), let duration = player?.currentItem?.duration {
            progressView.progress = Float(CMTimeGetSeconds(time) / CMTimeGetSeconds(duration))
        }
        
        if player?.isPlaying == true { player?.pause() }
        else { player?.play() }
    }
    
    
    // MARK: - Private
    
    private func checkState() {
        if worker.isTaskRunning {
            progressView.isHidden = false
            button.setTitle("Stop", for: .normal)
            return
        }
        
        if file == nil {
            if worker.hasDataToResume {
                progressView.isHidden = false
                button.setTitle("Resume", for: .normal)
            } else {
                progressView.isHidden = true
                button.setTitle("Load", for: .normal)
            }
            return
        }
        
        label.text = file?.lastPathComponent
        
        if player?.rate == 0 {
            progressView.isHidden = false
            button.setTitle("Play", for: .normal)
            return
        }
        
        progressView.isHidden = false
        button.setTitle("Pause", for: .normal)
    }
    
    private func load() {
        let path = "https://dl.dropbox.com/s/ksncs5whcayfd5a/video.mp4"
        label.text = URL(string: path)?.lastPathComponent
        progressView.progress = 0
        worker.loadFile(path: path)
        checkState()
    }
    
    private func play(url: URL) {
        file = url
        player?.pause()
        player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = (playerView?.frame)!
        view.layer.addSublayer(playerLayer)
        playerObservation = player?.observe(\.rate) { [weak self] _, _ in self?.checkState() }
        player?.play()
    }
    
    private func addPlayerProgressObserver() {
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: nil) { [weak self] _ in
            if let time = self?.player?.currentTime(), let duration = self?.player?.currentItem?.duration {
                self?.progressView.progress = Float(CMTimeGetSeconds(time) / CMTimeGetSeconds(duration))
            }
        }
    }
    
    private func show(error message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            // To close window
            UIApplication.shared.delegate?.window??.makeKeyAndVisible()
            window.isHidden = true
        }
        alert.addAction(ok)
        
        window.windowLevel = UIWindowLevelAlert
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
        rootViewController.show(alert, sender: nil)
    }
    
    
    
    // MARK: - MediaWorker Delegate
    
    func mediaWorker(_ worker: MediaWorker, didFinishLoadingTo url: URL, source: URL) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(source.lastPathComponent)
        print(destinationURL)
        
        // Cleanup
        try? fileManager.removeItem(at: destinationURL)
        
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            play(url: destinationURL)
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
        
        checkState()
    }
    
    func mediaWorker(_ worker: MediaWorker, didUpdateProgress progress: Float) {
        progressView.progress = progress
    }
    
    func mediaWorker(_ worker: MediaWorker, failWith error: Error) {
        show(error: error.localizedDescription)
        checkState()
    }
}



extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countOfCellDownload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomeCell
        
        cell.numberOfDownload.text = "Загрузка #\(countOfCellDownload[indexPath.row])"

        
        
        return cell
    }
    
}
