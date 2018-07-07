//
//  AVPlayerExtension.swift
//  videoLoader
//
//  Created by Mac on 07.07.2018.
//  Copyright © 2018 testOrg. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    var isPlaying: Bool {
        return rate > 0
    }
}
