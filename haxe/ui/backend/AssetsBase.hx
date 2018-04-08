package haxe.ui.backend;

import haxe.ui.backend.heaps.util.FontDetect;
import haxe.io.Bytes;
import haxe.ui.assets.ImageInfo;
import haxe.ui.assets.FontInfo;

class AssetsBase {
    public function new() {

    }

    public function embedFontSupported():Bool {
        return #if (lime || flash || js) true #else false #end;
    }

    private function getTextDelegate(resourceId:String):String {
        return null;
    }

    private function getImageInternal(resourceId:String, callback:ImageInfo->Void) {
        callback(null);
    }

    private function getImageFromHaxeResource(resourceId:String, callback:String->ImageInfo->Void) {
        callback(resourceId, null);
    }

    public function imageFromBytes(bytes:Bytes, callback:ImageInfo->Void) {

    }

    private function getFontInternal(resourceId:String, callback:FontInfo->Void) {
        FontDetect.onFontLoaded(resourceId, function(f) {
            var fontInfo = {
                data: f
            }
            callback(fontInfo);
        }, function(f) {
            callback(null);
        });
    }

    private function getFontFromHaxeResource(resourceId:String, callback:String->FontInfo->Void) {
        callback(resourceId, null);
    }
}