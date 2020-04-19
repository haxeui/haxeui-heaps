package haxe.ui.backend.heaps;

import h2d.Tile;

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
}