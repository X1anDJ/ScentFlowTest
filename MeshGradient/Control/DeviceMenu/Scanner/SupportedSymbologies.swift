//
//  SupportedSymbologies.swift
//  MeshGradient
//
//  Created by Dajun Xian on 9/22/25.
//

import AVFoundation

func supportedSymbologies() -> [AVMetadataObject.ObjectType] {
    var types: [AVMetadataObject.ObjectType] = [
        .qr, .aztec, .dataMatrix, .pdf417,
        .ean8, .ean13, .upce,
        .code39, .code39Mod43, .code93, .code128,
        .itf14, .interleaved2of5
    ]
    if #available(iOS 15.4, *) {
        // Placeholder for newer types if added later
    }
    return types
}
