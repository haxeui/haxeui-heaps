package haxe.ui.backend.heaps;

class HeapsApp extends hxd.App
{
    private static var instance:HeapsApp;
    public static function getInstance():HeapsApp {
        if (instance == null) {
            instance = new HeapsApp();
        }

        return instance;
    }

    public var onInitialized:Void->Void;

    override function init() {
        if (onInitialized != null) {
            onInitialized();
        }
    }

    override function update(dt:Float) {
        TimerBase.update();
    }
}
