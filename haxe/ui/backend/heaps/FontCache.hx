package haxe.ui.backend.heaps;

import h2d.Font;
import hxd.res.BitmapFont;
import hxd.res.Loader;

class FontCache {
    private static var _bitmapFontCache:Map<String, BitmapFont> = null;
    
    public static function getBitmapFont(resourceId:String):hxd.res.BitmapFont {
        if (_bitmapFontCache != null && _bitmapFontCache.exists(resourceId)) {
            return _bitmapFontCache.get(resourceId);
        }
        
        var loader:Loader = hxd.Res.loader;
        var bitmapFont:BitmapFont = null;
        try {
            bitmapFont = loader.load(resourceId).to(hxd.res.BitmapFont);
        } catch (e:Dynamic) {
            trace(e);
        }
        return bitmapFont;
    }
    
    public static function getFont(resourceId:String, ?fontSize:Int):Font {
        var bitmapFont = getBitmapFont(resourceId);
        if (bitmapFont == null) {
            return hxd.res.DefaultFont.get();
        }
        
        var f = bitmapFont.toSdfFont(fontSize);
        if (f == null) {
            return hxd.res.DefaultFont.get();
        }
        
        return f;
    }
}