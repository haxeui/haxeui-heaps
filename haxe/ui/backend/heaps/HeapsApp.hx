package haxe.ui.backend.heaps;

class HeapsApp extends hxd.App
{
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
