//
//  DragDropDelegate.swift
//  CacheSweep
    

import SwiftUI

struct DragDropDelegate: DropDelegate {
    let target: CacheLocation
    let model: ApplicationVM

    func dropEntered(info: DropInfo) {
        model.moveDraggedLocation(to: target)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        model.finishDragging()
        return true
    }
}
