#!/usr/bin/env swift
import Foundation

// Deterministic PHK demo AppIcon generation from the permitted project photograph.
// Use macOS sips (headless) instead of an NSGraphicsContext, which can fail in CI.
guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift scripts/generate_phk_icons.swift <photo.jpg> <AppIcon.appiconset>\n",stderr)
    exit(2)
}
let source=URL(fileURLWithPath:CommandLine.arguments[1])
let destination=URL(fileURLWithPath:CommandLine.arguments[2],isDirectory:true)
guard FileManager.default.isReadableFile(atPath:source.path) else {
    fputs("Cannot read icon photo at \(source.path)\n",stderr);exit(3)
}
try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)

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
func runSips(_ args:[String]) throws {
    let process=Process()
    process.executableURL=URL(fileURLWithPath:"/usr/bin/sips")
    process.arguments=args
    let out=Pipe()
    process.standardOutput=out
    process.standardError=out
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        let details=String(data:out.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8) ?? ""
        throw NSError(domain:"PHKIconSips",code:Int(process.terminationStatus),
              userInfo:[NSLocalizedDescriptionKey:"sips failed: \(details)"])
    }
}
let temp=destination.appendingPathComponent(".phk-resize-tmp.png")
defer {try? FileManager.default.removeItem(at:temp)}
for icon in icons {
    let pixels=String(icon.pixels)
    try runSips(["-s","format","png","--resampleHeightWidthMax",pixels,
                 source.path,"--out",temp.path])
    // Letterbox rather than stretch/crop the owner's picture, with opaque navy fill.
    try runSips(["--padToHeightWidth",pixels,pixels,"--padColor","0C1726",
                 temp.path,"--out",destination.appendingPathComponent(icon.filename).path])
}
let images=icons.map { i -> [String:String] in
    ["filename":i.filename,"idiom":i.idiom,"size":i.size,"scale":i.scale]
}
let content:[String:Any]=["images":images,"info":["author":"xcode","version":1]]
let data=try JSONSerialization.data(withJSONObject:content,options:[.prettyPrinted,.sortedKeys])
try data.write(to:destination.appendingPathComponent("Contents.json"),options:.atomic)
print("Generated \(icons.count) opaque PHK app icons using macOS sips and project car photo.")
