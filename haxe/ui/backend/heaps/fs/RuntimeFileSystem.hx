package haxe.ui.backend.heaps.fs;

import hxd.fs.LoadedBitmap;
import hxd.fs.NotFound;
import hxd.fs.FileEntry;
import hxd.fs.FileSystem;

#if !macro

@:allow(haxe.ui.backend.heaps.fs.RuntimeFileSystem)
@:access(haxe.ui.backend.heaps.fs.RuntimeFileSystem)
private class RuntimeEntry extends FileEntry {

    var fs : RuntimeFileSystem;
    var relPath : String;

    var bytes : haxe.io.Bytes;
    var readPos : Int = 0;

    var isReady:Bool = false;
    override function get_isAvailable() return isReady;

    function new(fs, name, relPath) {
        this.fs = fs;
        this.name = name;
        this.relPath = relPath;
    }

    override public function getSign() : Int {
        var old = readPos;
        getBytes();
        var sign:Int = bytes.get(0) | (bytes.get(1) << 8) | (bytes.get(2) << 16) | (bytes.get(3) << 24);
        readPos = old;
        return sign;
    }

    override public function getBytes() : haxe.io.Bytes {
        if( bytes == null )
            open();
        return bytes;
    }

    override public function open() {
        try {
            var result = Http.requestUrl(relPath);
            bytes = haxe.io.Bytes.ofString(result);
            readPos = 0;
            isReady = true;
        } catch (e:Dynamic) {

        }
    }

    override public function skip( nbytes : Int ) {
        readPos += nbytes;
    }

    override public function readByte() : Int {
        return bytes.get(readPos++);
    }

    override public function read( out : haxe.io.Bytes, pos : Int, size : Int ) : Void {
        out.blit(pos, bytes, readPos, size);
        readPos += size;
    }

    override public function close() {
        bytes = null;
        readPos = 0;
    }

    override public function load( ?onReady : Void -> Void ) : Void {
		if( onReady != null ) haxe.Timer.delay(onReady, 1);
    }

    override public function loadBitmap( onLoaded : LoadedBitmap -> Void ) : Void {
        /*#if flash
		var loader = new flash.display.Loader();
		loader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR, function(e:flash.events.IOErrorEvent) {
			throw Std.string(e) + " while loading " + relPath;
		});
		loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
			var content : flash.display.Bitmap = cast loader.content;
			onLoaded(new LoadedBitmap(content.bitmapData));
			loader.unload();
		});
		open();
		loader.loadBytes(bytes);
		close(); // flash will copy bytes content in loadBytes() !
		#else

        lime.graphics.Image.fromBytes(bytes, function(img) {
            onLoaded(new hxd.fs.LoadedBitmap(img));
        });
        close();
        #end*/
    }

    override function get_path() {
        return relPath == "." ? "<root>" : relPath;
    }

    override public function exists( name : String ) {
        return fs.exists(relPath == "." ? name : relPath + "/" + name);
    }

    override public function get( name : String ) {
        return fs.get(relPath == "." ? name : relPath + "/" + name);
    }

    override public function iterator():hxd.impl.ArrayIterator<FileEntry> {
        return new hxd.impl.ArrayIterator(fs.subFiles(relPath));
    }

    override function get_isDirectory() {
        return fs.isDirectory(relPath);
    }

    override function get_size() {
        open();
        return bytes.length;
    }
}

#end

class RuntimeFileSystem implements FileSystem {

    public var root(default,null) : String;

    public function new( dir : String ) {
        root = dir;
    }

    public function exists(path:String) {
//        var r = root;
//        for (p in splitPath(path)){
//            r = Reflect.field(r, p);
//            if( r == null ) return false;
//        }
        return true;
    }


    public function get(path:String) : FileEntry {
        if( !exists(path) )
            throw new NotFound(path);

        return new RuntimeEntry(this, path.split("/").pop(), path);
    }

    public function getRoot() : FileEntry {
        return new RuntimeEntry(this, "root", ".");
    }

    public function dispose() {
    }

    function splitPath( path : String ) {
        return path == "." ? [] : path.split("/");
    }

    function subFiles( path : String ) : Array<FileEntry> {
        var out:Array<FileEntry> = [];
//        var all = lime.Assets.list();
//        for( f in all )
//        {
//            if( f != path && StringTools.startsWith(f, path) )
//                out.push(get(f));
//        }
        return out;
    }

    function isDirectory( path : String ) {
//        return subFiles(path).length > 0;
        return false;
    }
}
