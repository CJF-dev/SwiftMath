
import Foundation
import CoreText

//
//  Created by Mike Griebling on 2022-12-31.
//  Translated from an Objective-C implementation by Kostub Deshmukh.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

public class MTFont {
    
    var defaultCGFont: CGFont!
    var ctFont: CTFont!
    var mathTable: MTFontMathTable?
    var rawMathTable: NSDictionary?
    
    init() {}
    
    /// `MTFont(fontWithName:)` does not load the complete math font, it only has about half the glyphs of the full math font.
    /// In particular it does not have the math italic characters which breaks our variable rendering.
    /// So we first load a CGFont from the file and then convert it to a CTFont.
    convenience init(fontWithName name: String, size:CGFloat) {
        self.init()
        //print("Loading font \(name)")
        let bundle = MTFont.fontBundle
        let fontPath = bundle.path(forResource: name, ofType: "otf")
        let fontDataProvider = CGDataProvider(filename: fontPath!)
        self.defaultCGFont = CGFont(fontDataProvider!)!
        //print("Num glyphs: \(self.defaultCGFont.numberOfGlyphs)")

        self.ctFont = MTFont.makeCTFont(self.defaultCGFont, size: size)

        //print("Loading associated .plist")
        let mathTablePlist = bundle.url(forResource:name, withExtension:"plist")
        self.rawMathTable = NSDictionary(contentsOf: mathTablePlist!)
        self.mathTable = MTFontMathTable(withFont:self, mathTable:rawMathTable!)
    }

    /// Fallback fonts (in priority order) used to render characters — chiefly
    /// CJK ideographs — that the math font lacks. Attached as a CoreText
    /// cascade list so `CTLine` substitutes them automatically. Without this,
    /// a CTFont built straight from a CGFont has an empty cascade list and
    /// missing glyphs render as `.notdef` (Chinese text disappears).
    static let fallbackFontNames: [String] = [
        "PingFang SC", "PingFang TC", "Hiragino Sans GB",
        "Heiti SC", "STHeiti", "Apple SD Gothic Neo", "Songti SC"
    ]

    /// Builds a CTFont from `cgFont` with a CJK fallback cascade list so that
    /// Chinese/Japanese/Korean glyphs render via font substitution.
    static func makeCTFont(_ cgFont: CGFont, size: CGFloat) -> CTFont {
        let base = CTFontCreateWithGraphicsFont(cgFont, size, nil, nil)
        let cascade = fallbackFontNames.map { name in
            CTFontDescriptorCreateWithAttributes(
                [kCTFontNameAttribute: name as CFString] as CFDictionary)
        }
        let descriptor = CTFontDescriptorCreateWithAttributes(
            [kCTFontCascadeListAttribute: cascade as CFArray] as CFDictionary)
        return CTFontCreateCopyWithAttributes(base, size, nil, descriptor)
    }

    static var fontBundle:Bundle {
        // Uses bundle for class so that this can be access by the unit tests.
        Bundle(url: Bundle.module.url(forResource: "mathFonts", withExtension: "bundle")!)!
    }

    /** Returns a copy of this font but with a different size. */
    public func copy(withSize size: CGFloat) -> MTFont {
        let newFont = MTFont()
        newFont.defaultCGFont = self.defaultCGFont
        newFont.ctFont = MTFont.makeCTFont(self.defaultCGFont, size: size)
        newFont.rawMathTable = self.rawMathTable
        newFont.mathTable = MTFontMathTable(withFont: newFont, mathTable: newFont.rawMathTable!)
        return newFont
    }
    
    func get(nameForGlyph glyph:CGGlyph) -> String {
        let name = defaultCGFont.name(for: glyph) as? String
        return name ?? ""
    }
    
    func get(glyphWithName name:String) -> CGGlyph {
        defaultCGFont.getGlyphWithGlyphName(name: name as CFString)
    }
    
    /** The size of this font in points. */
    public var fontSize:CGFloat { CTFontGetSize(self.ctFont) }
    
    deinit {
        self.ctFont = nil
        self.defaultCGFont = nil
    }
    
}
