package haxe.ui.backend;

import haxe.io.Bytes;
import haxe.ui.assets.FontInfo;
import hxd.Res;
import hxd.fs.BytesFileSystem.BytesFileEntry;
import hxd.res.Image;

class AssetsImpl extends AssetsBase { 
    public function embedFontSupported():Bool {
        return #if (lime || flash || js) true #else false #end;
    }

    /** How much bigger than their plain name the `name@4x.png` images are. */
    public static inline var HI_RES_FACTOR:Int = 4;

    /** Loaders for images drawn from vectors at whatever size they are shown (ImageDisplayImpl
        renders them per size). Each takes a resource id; they are asked, in order, before any
        bitmap is looked for. A loader returns null when the id is not one of its images (the next
        loader, then the bitmap path, gets it); a source to draw it with; or a null `source` when
        the id is its but it cannot draw it (a file that would not parse), which is no image: the
        bitmap decoder is not tried on it. */
    public static var vectorLoaders:Array<String->Null<{width:Int, height:Int, source:Null<haxe.ui.backend.heaps.VectorSource>}>> = [];

    private override function getImageInternal(resourceId:String, callback:haxe.ui.assets.ImageInfo->Void) {
        for (load in vectorLoaders) {
            var v = load(resourceId);
            if (v != null) {
                callback(v.source == null ? null : {width: v.width, height: v.height, data: new haxe.ui.backend.heaps.VectorBitmapData(v.source)});
                return;
            }
        }
        try {
            var loader:hxd.res.Loader = hxd.Res.loader;
            if (loader != null) {
                // A `name@4x.png` next to `name.png` is drawn in its place: it measures as the plain
                // one, and ImageDisplayImpl draws it mipmapped, so it stays sharp at any Toolkit.scale
                // instead of the plain one being stretched.
                var dot = resourceId.lastIndexOf(".");
                var hiRes = dot > 0 ? resourceId.substr(0, dot) + "@" + HI_RES_FACTOR + "x" + resourceId.substr(dot) : null;
                var factor = 1;
                if (hiRes != null && resourceId.indexOf("@") < 0 && loader.exists(hiRes)) {
                    resourceId = hiRes;
                    factor = HI_RES_FACTOR;
                }
                if (loader.exists(resourceId)) {
                    var image:Image = loader.load(resourceId).toImage();
                    var size:Dynamic = image.getSize();
                    var imageInfo:haxe.ui.assets.ImageInfo = {
                        width: Std.int(size.width / factor),
                        height: Std.int(size.height / factor),
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

    private override function getImageFromHaxeResource(resourceId:String, callback:String->haxe.ui.assets.ImageInfo->Void) {
        var bytes = Resource.getBytes(resourceId);
        imageFromBytes(bytes, function(imageInfo) {
            callback(resourceId, imageInfo);
        });
    }

    public override function imageFromBytes(bytes:Bytes, callback:haxe.ui.assets.ImageInfo->Void) {
        if (bytes == null) {
            callback(null);
            return;
        }

        try {
            var entry:BytesFileEntry = new BytesFileEntry("", bytes);
            var image:Image = new Image(entry);

            var size:Dynamic = image.getSize();
            var imageInfo:haxe.ui.assets.ImageInfo = {
                width: size.width,
                height: size.height,
                data: image.toBitmap()
            };
            callback(imageInfo);
        } catch (e:Dynamic) {
            callback(null);
        }
    }

    public override function imageInfoFromImageData(imageData:ImageData):haxe.ui.assets.ImageInfo {
        var imageInfo:haxe.ui.assets.ImageInfo = {
            width: imageData.width,
            height: imageData.height,
            data: imageData
        };
        return imageInfo;
    }
    
    private override function getFontInternal(resourceId:String, callback:FontInfo->Void) {
        try {
            var font = hxd.Res.loader.loadCache(resourceId, hxd.res.BitmapFont);
            callback({
                name: resourceId,
                data: font
            });
        } catch (error:Dynamic) {
            #if debug
            trace("WARNING: problem loading font '" + resourceId + "' (" + error + ")");
            #end
            callback(null);
        }
    }
}
