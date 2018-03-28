package haxe.ui.backend.heaps;

import haxe.ui.backend.heaps.fs.RuntimeFileSystem;
class HeapsApp extends hxd.App
{
    private static var instance:HeapsApp;
    public static function getInstance():HeapsApp {
        if (instance == null) {
            instance = new HeapsApp();
        }

        return instance;
    }

    public var loader(default, null):hxd.res.Loader;

    public var onInitialized:Void->Void;

    override function init() {
        loader = new hxd.res.Loader(new RuntimeFileSystem("."));

        if (onInitialized != null) {
            onInitialized();
        }
    }

    override function update(dt:Float) {
        TimerBase.update();
    }
}
