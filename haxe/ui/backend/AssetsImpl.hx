package haxe.ui.backend;

import haxe.io.Bytes;
import haxe.ui.assets.FontInfo;
import haxe.ui.assets.ImageInfo;
import hxd.Res;
import hxd.fs.BytesFileSystem.BytesFileEntry;
import hxd.res.Image;

class AssetsImpl extends AssetsBase { 
    public function embedFontSupported():Bool {
        return #if (lime || flash || js) true #else false #end;
    }

    private override function getImageInternal(resourceId:String, callback:ImageInfo->Void) {
        try {
            var loader:hxd.res.Loader = hxd.Res.loader;
            if (loader != null) {
                if (loader.exists(resourceId)) {
                    var image:Image = loader.load(resourceId).toImage();
                    var size:Dynamic = image.getSize();
                    var imageInfo:ImageInfo = {
                        width: size.width,
                        height: size.height,
                        data: image.toBitmap()
                    };
                    callback(imageInfo);
                } else {
                    callback(null);
                }
            } else {
                callback(null);
            }
        } catch (e:Dynamic) {
            trace(e);
            callback(null);
        }
    }

    private override function getImageFromHaxeResource(resourceId:String, callback:String->ImageInfo->Void) {
        var bytes = Resource.getBytes(resourceId);
        imageFromBytes(bytes, function(imageInfo) {
            callback(resourceId, imageInfo);
        });
    }

    public override function imageFromBytes(bytes:Bytes, callback:ImageInfo->Void) {
        if (bytes == null) {
            callback(null);
            return;
        }

        var entry:BytesFileEntry = new BytesFileEntry("", bytes);
        var image:Image = new Image(entry);

        var size:Dynamic = image.getSize();
        var imageInfo:ImageInfo = {
            width: size.width,
            height: size.height,
            data: image.toBitmap()
        };
        callback(imageInfo);
    }

    private override function getFontInternal(resourceId:String, callback:FontInfo->Void) {
        #if js
        haxe.ui.backend.heaps.util.FontDetect.onFontLoaded(resourceId, function(f) {
            var fontInfo = {
                data: f
            }
            callback(fontInfo);
        }, function(f) {
            callback(null);
        });
        #else
        callback(null);
        #end
    }
}