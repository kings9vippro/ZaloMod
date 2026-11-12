#!/usr/bin/env swift
import AppKit
import Foundation

// First-party PHK app icon generator. Uses the car image already supplied for this project.
// This does NOT produce Zalo's official app icon.
guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift scripts/generate_phk_icons.swift <photo.jpg> <AppIcon.appiconset>\n", stderr)
    exit(2)
}

let sourceURL=URL(fileURLWithPath:CommandLine.arguments[1])
let destination=URL(fileURLWithPath:CommandLine.arguments[2], isDirectory:true)
guard let original=NSImage(contentsOf:sourceURL),
      original.size.width>0,original.size.height>0 else {
    fputs("Cannot read source photograph\n",stderr)
    exit(3)
}
try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)

// Icon compatibility set: eight iPhone sizes, two iPad sizes, and a marketing master.
struct Icon {
    let filename:String
    let idiom:String
    let size:String
    let scale:String
    let pixels:Int
}
let icons=[
    Icon(filename:"PHK-iPhone-20-2x.png",idiom:"iphone",size:"20x20",scale:"2x",pixels:40),
    Icon(filename:"PHK-iPhone-20-3x.png",idiom:"iphone",size:"20x20",scale:"3x",pixels:60),
    Icon(filename:"PHK-iPhone-29-2x.png",idiom:"iphone",size:"29x29",scale:"2x",pixels:58),
    Icon(filename:"PHK-iPhone-29-3x.png",idiom:"iphone",size:"29x29",scale:"3x",pixels:87),
    Icon(filename:"PHK-iPhone-40-2x.png",idiom:"iphone",size:"40x40",scale:"2x",pixels:80),
    Icon(filename:"PHK-iPhone-40-3x.png",idiom:"iphone",size:"40x40",scale:"3x",pixels:120),
    Icon(filename:"PHK-iPhone-60-2x.png",idiom:"iphone",size:"60x60",scale:"2x",pixels:120),
    Icon(filename:"PHK-iPhone-60-3x.png",idiom:"iphone",size:"60x60",scale:"3x",pixels:180),
    Icon(filename:"PHK-iPad-76-1x.png",idiom:"ipad",size:"76x76",scale:"1x",pixels:76),
    Icon(filename:"PHK-iPad-76-2x.png",idiom:"ipad",size:"76x76",scale:"2x",pixels:152),
    Icon(filename:"PHK-iPad-83.5-2x.png",idiom:"ipad",size:"83.5x83.5",scale:"2x",pixels:167),
    Icon(filename:"PHK-Marketing-1024.png",idiom:"ios-marketing",size:"1024x1024",scale:"1x",pixels:1024)
]

// Draw the master once at full resolution; downsample with Quartz for predictable colors.
func renderMaster() throws -> Data {
    let pixels=1024
    guard let bitmap=NSBitmapImageRep(
        bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,
        bitsPerSample:8,samplesPerPixel:3,hasAlpha:false,isPlanar:false,
        colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0),
          let context=NSGraphicsContext(bitmapImageRep:bitmap) else {
        throw NSError(domain:"PHKIcon",code:1)
    }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current=context
    context.imageInterpolation = .high
    let rect=NSRect(x:0,y:0,width:pixels,height:pixels)
    NSColor(calibratedRed:0.045,green:0.080,blue:0.135,alpha:1).setFill()
    NSRectFill(rect)
    let scale=max(CGFloat(pixels)/original.size.width,CGFloat(pixels)/original.size.height)
    let width=original.size.width*scale,height=original.size.height*scale
    let content=NSRect(x:(CGFloat(pixels)-width)/2,y:(CGFloat(pixels)-height)/2,
                       width:width,height:height)
    original.draw(in:content,from:NSRect(origin:.zero,size:original.size),
                  operation:.sourceOver,fraction:1)
    // A dark brand band for legibility, not the official Zalo icon.
    NSColor(calibratedRed:0.025,green:0.035,blue:0.055,alpha:0.86).setFill()
    NSRectFill(NSRect(x:0,y:0,width:pixels,height:228))
    let title=NSAttributedString(string:"PHK",attributes:[
        .font:NSFont.systemFont(ofSize:154,weight:.heavy),
        .foregroundColor:NSColor.white
    ])
    let labelSize=title.size()
    title.draw(at:NSPoint(x:(CGFloat(pixels)-labelSize.width)/2,
                           y:(228-labelSize.height)/2))
    context.flushGraphics()
    guard let encoded=bitmap.representation(using:.png,properties:[:]) else {
        throw NSError(domain:"PHKIcon",code:2)
    }
    return encoded
}
let master=try renderMaster()
let masterBitmap=NSBitmapImageRep(data:master)!
for icon in icons {
    let url=destination.appendingPathComponent(icon.filename)
    if icon.pixels==1024 {
        try master.write(to:url,options:.atomic)
        continue
    }
    guard let bitmap=NSBitmapImageRep(
        bitmapDataPlanes:nil,pixelsWide:icon.pixels,pixelsHigh:icon.pixels,
        bitsPerSample:8,samplesPerPixel:3,hasAlpha:false,isPlanar:false,
        colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0),
          let context=NSGraphicsContext(bitmapImageRep:bitmap) else {
        throw NSError(domain:"PHKIcon",code:3)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current=context
    context.imageInterpolation = .high
    let resized=NSImage(size:NSSize(width:1024,height:1024))
    resized.addRepresentation(masterBitmap)
    resized.draw(in:NSRect(x:0,y:0,width:icon.pixels,height:icon.pixels),
                 from:NSRect(x:0,y:0,width:1024,height:1024),
                 operation:.copy,fraction:1)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let png=bitmap.representation(using:.png,properties:[:]) else {
        throw NSError(domain:"PHKIcon",code:4)
    }
    try png.write(to:url,options:.atomic)
}
let records=icons.map { icon -> [String:String] in
    ["filename":icon.filename,"idiom":icon.idiom,"size":icon.size,"scale":icon.scale]
}
let content:[String:Any]=["images":records,"info":["author":"xcode","version":1]]
let json=try JSONSerialization.data(withJSONObject:content,options:[.prettyPrinted,.sortedKeys])
try json.write(to:destination.appendingPathComponent("Contents.json"),options:.atomic)
print("Generated \(icons.count) RGB PNG icons for Zalo PHK demo, using the existing user-supplied car image.")
