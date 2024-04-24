package haxe.ui.backend.heaps;

import h2d.Tile;
import haxe.ui.geom.Rectangle;
import haxe.ui.util.ColorUtil;

class TileCache {
    private static var _cache:Map<String, Tile> = new Map<String, Tile>();
    
    public static function set(resourceId:String, tile:Tile, trc:Rectangle = null):Tile {
        _cache.set(buildCacheKey(resourceId, trc), tile);
        return tile;
    }
    
    public static function get(resourceId:String, trc:Rectangle = null):Tile {
        return _cache.get(buildCacheKey(resourceId, trc));
    }
    
    private static inline function buildCacheKey(resourceId:String, trc:Rectangle = null):String {
        var key = resourceId;
        if (trc != null) {
            key += "_" + trc.left + "_" + trc.top + "_" + trc.width + "_" + trc.height;
        }
        return key;
    }

    public static function getGradient(type:String, startCol:Int, endCol:Int, size:Int = 256, alpha:Int = 255):Tile {
        var key = type + "_" + startCol + "_" + endCol + "_" + size + "_" + alpha;
        if (_cache.exists(key)) {
            return _cache.get(key);
        }

        var alphaMask = alpha << 24;
        var arr = ColorUtil.buildColorArray(startCol, endCol, size);
        var tile:Tile = null;
        if (type == "vertical") {
            var gradient = new hxd.BitmapData(1, size);
            var y = 0;
            for (col in arr) {
                gradient.line(0, y, 1, y, alphaMask | col);
                y++;
            }
            tile = h2d.Tile.fromBitmap(gradient);
        } else if (type == "horizontal") {
            var gradient = new hxd.BitmapData(size, 1);
            var x = 0;
            for (col in arr) {
                gradient.line(x, 0, x, 1, alphaMask | col);
                x++;
            }
            tile = h2d.Tile.fromBitmap(gradient);
        }
        
        return tile;
    }
}