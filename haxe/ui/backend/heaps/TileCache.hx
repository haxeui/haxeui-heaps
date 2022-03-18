package haxe.ui.backend.heaps;

import h2d.Tile;
import haxe.ui.util.ColorUtil;

class TileCache {
    private static var _cache:Map<String, Tile> = new Map<String, Tile>();
    
    public static function set(resourceId:String, tile:Tile):Tile {
        _cache.set(resourceId, tile);
        return tile;
    }
    
    public static function get(resourceId:String):Tile {
        return _cache.get(resourceId);
    }
    
    public static function exists(resourceId:String):Bool {
        return _cache.exists(resourceId);
    }
    
    public static function getGradient(type:String, startCol:Int, endCol:Int, size:Int = 256):Tile {
        var key = type + "_" + startCol + "_" + endCol + "_" + size;
        if (_cache.exists(key)) {
            return _cache.get(key);
        }
        
        var arr = ColorUtil.buildColorArray(startCol, endCol, size);
        var tile:Tile = null;
        if (type == "vertical") {
            var gradient = new hxd.BitmapData(1, size);
            var y = 0;
            for (col in arr) {
                gradient.line(0, y, 1, y, 0xFF000000 | col);
                y++;
            }
            tile = h2d.Tile.fromBitmap(gradient);
        } else if (type == "horizontal") {
            var gradient = new hxd.BitmapData(size, 1);
            var x = 0;
            for (col in arr) {
                gradient.line(x, 0, x, 1, 0xFF000000 | col);
                x++;
            }
            tile = h2d.Tile.fromBitmap(gradient);
        }
        
        return tile;
    }
}