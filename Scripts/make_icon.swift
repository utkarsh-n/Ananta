import AppKit
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 4096, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(NSColor(srgbRed: 0.066, green: 0.118, blue: 0.161, alpha: 1).cgColor)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
let gold = NSColor(srgbRed: 0.84, green: 0.68, blue: 0.42, alpha: 1).cgColor
context.setStrokeColor(gold)
context.setLineWidth(2)
for radius in [330.0, 370, 400] {
    context.setAlpha(radius == 370 ? 0.4 : 0.18)
    context.strokeEllipse(in: CGRect(x: 512-radius, y: 512-radius, width: radius*2, height: radius*2))
}
context.setAlpha(1)
for angle in [-60.0, -30, 0, 30, 60] {
    context.saveGState()
    context.translateBy(x: 512, y: 335)
    context.rotate(by: angle * .pi / 180)
    let petal = CGMutablePath()
    petal.move(to: .zero)
    petal.addQuadCurve(to: CGPoint(x: 0, y: 438), control: CGPoint(x: -235, y: 270))
    petal.addQuadCurve(to: .zero, control: CGPoint(x: 235, y: 270))
    context.addPath(petal)
    context.setLineWidth(8)
    context.strokePath()
    context.restoreGState()
}
context.setFillColor(gold)
for point in [CGPoint(x: 512, y: 881), CGPoint(x: 184, y: 685), CGPoint(x: 840, y: 337)] {
    context.fillEllipse(in: CGRect(x: point.x-6, y: point.y-6, width: 12, height: 12))
}
let output = CommandLine.arguments[1]
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write icon") }
