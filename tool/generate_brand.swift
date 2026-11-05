// Rebuild native icon/splash PNGs from the geometry in assets/brand/tiko.svg.
// Run from the project root: swift tool/generate_brand.swift
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func render(_ size: Int, _ path: String, markOnly: Bool = false) throws {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
      bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    ctx.translateBy(x: 0, y: 1024)
    ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(CGColor(red: 0, green: 107.0/255, blue: 94.0/255, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    for rect in [CGRect(x: 280, y: 292, width: 464, height: 104), CGRect(x: 460, y: 340, width: 104, height: 392)] {
      ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 52, cornerHeight: 52, transform: nil)); ctx.fillPath()
    }
    ctx.setFillColor(CGColor(red: 184.0/255, green: 242.0/255, blue: 213.0/255, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: 640, y: 628, width: 104, height: 104))
    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { throw NSError(domain: "TikoBrand", code: 1) }
}
let iconFolder = "ios/Runner/Assets.xcassets/AppIcon.appiconset/"
let content = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: iconFolder + "Contents.json"))) as! [String: Any]
for image in content["images"] as! [[String: String]] {
    let points = Double(image["size"]!.split(separator: "x")[0])!
    let scale = Double(image["scale"]!.dropLast())!
    try render(Int(points * scale), iconFolder + image["filename"]!)
}
for (density, size) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
    try render(size, "android/app/src/main/res/mipmap-\(density)/ic_launcher.png")
}
for scale in 1...3 {
    try render(96 * scale, "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage\(scale == 1 ? "" : "@\(scale)x").png")
}
try render(256, "assets/brand/tiko.png")
