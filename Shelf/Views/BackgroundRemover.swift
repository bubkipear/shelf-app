import Vision
import UIKit
import CoreImage.CIFilterBuiltins

struct BackgroundRemover {

    static func process(_ image: UIImage) async -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
        } catch {
            return image
        }

        guard let result = request.results?.first else { return image }

        do {
            let mask = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            return apply(mask: mask, to: image) ?? image
        } catch {
            return image
        }
    }

    private static func apply(mask: CVPixelBuffer, to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        let maskCI  = CIImage(cvPixelBuffer: mask)

        let scaleX = ciImage.extent.width  / maskCI.extent.width
        let scaleY = ciImage.extent.height / maskCI.extent.height
        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let blend = CIFilter.blendWithMask()
        blend.inputImage      = ciImage
        blend.maskImage       = scaledMask
        blend.backgroundImage = CIImage.empty()

        guard let output = blend.outputImage else { return nil }

        let context = CIContext()
        guard let out = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: out)
    }
}
