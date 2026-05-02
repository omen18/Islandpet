//
//  IslandPetWidgetBundle.swift
//  IslandPetWidgetExtension
//

import WidgetKit
import SwiftUI

@main
struct IslandPetWidgetBundle: WidgetBundle {
    var body: some Widget {
        IslandPetLockWidget()
        IslandPetLiveActivity()
    }
}
