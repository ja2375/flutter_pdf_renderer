import Flutter
import UIKit

public class SwiftFlutterPdfRendererPlugin: NSObject, FlutterPlugin {
    
    private let registrar: FlutterPluginRegistrar;
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "rackberg.flutter_pdf_renderer", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPdfRendererPlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "renderPdf") {
            let arguments = call.arguments as! NSDictionary
            result(getPathsForAllPages(resourcePath: arguments["path"] as! String))
        }
    }
    
    private func getPathsForAllPages(resourcePath: String) -> [String] {
        var paths: [String] = [String]()
        
        do {
            let pdfdata = try NSData(contentsOfFile: resourcePath, options: NSData.ReadingOptions.init(rawValue: 0))
            let pdfData = pdfdata as CFData
            let provider:CGDataProvider = CGDataProvider(data: pdfData)!
            let pdfDoc:CGPDFDocument = CGPDFDocument(provider)!
            let numberOfPages:Int = pdfDoc.numberOfPages
            for i in 1...numberOfPages {
                if let renderedPagePath: String = renderPage(pdfDoc: pdfDoc, page: i) {
                    paths.append(renderedPagePath)
                }
            }
        } catch {
            // Handle error...
        }
        
        return paths
    }
    
    private func renderPage(pdfDoc:CGPDFDocument, page:Int) -> String? {
        let pdfPage:CGPDFPage = pdfDoc.page(at: page)!
        var pageRect:CGRect = pdfPage.getBoxRect(.mediaBox)
        pageRect.size = CGSize(width: pageRect.size.width, height: pageRect.size.height)
        
        UIGraphicsBeginImageContext(pageRect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.translateBy(x: 0.0, y: pageRect.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.concatenate(pdfPage.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
        context.drawPDFPage(pdfPage)
        let pdfImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        if let savedPath = storeImageToTemporaryDirectory(image: pdfImage) {
            return savedPath.absoluteString.replacingOccurrences(of: "file://", with: "")
        }
        
        return nil
    }
    
    private func storeImageToTemporaryDirectory(image: UIImage) -> URL? {
        guard let data = image.pngData() else {
            return nil
        }
        let fileURL = TemporaryFileURL(extension: "pdf")
        do {
            try data.write(to: fileURL.contentURL)
            return fileURL.contentURL
        } catch {
            return nil
        }
    }
}

public final class TemporaryFileURL: ManagedURL {
    public let contentURL: URL
    
    public init(extension ext: String) {
        contentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }
}

public protocol ManagedURL {
    var contentURL: URL { get }
    func keepAlive()
}

public extension ManagedURL {
    public func keepAlive() {}
}

extension URL: ManagedURL {
    public var contentURL: URL { return self }
    
}
