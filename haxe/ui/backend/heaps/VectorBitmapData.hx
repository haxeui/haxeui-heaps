package haxe.ui.backend.heaps;

/** Carries a VectorSource through haxeui-core, which passes an ImageInfo's `data` along without
    looking inside it. Its own pixels (1x1) are never drawn. */
class VectorBitmapData extends hxd.BitmapData {
    public final source:VectorSource;

    public function new(source:VectorSource) {
        super(1, 1);
        this.source = source;
    }
}
