import Flutter
import UIKit

public class FastImageEditorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    forceSymbolRetention()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  @inline(never)
  private static func forceSymbolRetention() {
    var dummyInput: [UInt8] = [0]
    var outPtr: UnsafeMutablePointer<UInt8>? = nil
    var outSize: Int32 = 0

    _ = image_edit_blur(&dummyInput, 0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    _ = image_edit_sepia(&dummyInput, 0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    _ = image_edit_saturation(&dummyInput, 0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    _ = image_edit_brightness(&dummyInput, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    _ = image_edit_contrast(&dummyInput, 0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    _ = image_edit_sharpen(&dummyInput, 0, 1.0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    _ = image_edit_grayscale(&dummyInput, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, &outPtr, &outSize, 90)
    free_buffer(nil)
  }
}
