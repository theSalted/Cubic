import Foundation
import os
import RealityKit
import Metal

/// Checks to make sure at least one GPU meets the minimum requirements for object reconstruction. At
/// least one GPU must be a "high power" device, which means it has at least 4 GB of RAM, provides
/// barycentric coordinates to the fragment shader, and is running on an Apple silicon Mac or an Intel Mac
/// with a discrete GPU.
private func supportsObjectReconstruction() -> Bool {
    for device in MTLCopyAllDevices() where
        !device.isLowPower &&
         device.areBarycentricCoordsSupported &&
         device.recommendedMaxWorkingSetSize >= UInt64(4e9) {
        return true
    }
    return false
}

/// Returns `true` if at least one GPU has hardware support for ray tracing. The GPU that supports ray
/// tracing need not be the same GPU that supports object reconstruction.
private func supportsRayTracing() -> Bool {
    for device in MTLCopyAllDevices() where device.supportsRaytracing {
        return true
    }
    return false
}

/// Returns `true` if the current hardware supports Object Capture.
func supportsObjectCapture() -> Bool {
    return supportsObjectReconstruction() && supportsRayTracing()
}


