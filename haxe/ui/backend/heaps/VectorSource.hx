package haxe.ui.backend.heaps;

/** An image drawn from something that can be rendered at any size (see AssetsImpl.vectorLoaders):
    ImageDisplayImpl asks for a tile of exactly the pixels it covers on screen, and gives it back
    when it needs another size or is done. The source owns the tiles: they are never disposed here. */
interface VectorSource {
    function acquire(w:Int, h:Int):h2d.Tile;
    function release(tile:h2d.Tile):Void;
}
