package haxe.ui.backend;
import haxe.ui.core.Screen;

private class HeapsApp extends hxd.App {
    public var onInit:Void->Void = null;
    public var onUpdate:Float->Void = null;
    
    private override function init() {
        super.init();
        Screen.instance.root = this.s2d;
        if (onInit != null) {
            onInit();
        }
    }
    
    private override function update(dt:Float) {
        if (onUpdate != null) {
            onUpdate(dt);
        }
    }
}

class AppImpl extends AppBase {
    private var _app:HeapsApp;
    
    public function new() {
        _app = new HeapsApp();
        _app.onInit = onHeapsInit;
        _app.onUpdate = onHeapsUpdate;
    }
    
    private function onHeapsInit() {
        #if js
        //hxd.Res.initLocal();
        hxd.Res.initEmbed();
        #else
        hxd.Res.initEmbed();
        #end
        
        if (Toolkit.backendProperties.exists("haxe.ui.heaps.engine.background.color")) {
            h3d.Engine.getCurrent().backgroundColor = Toolkit.backendProperties.getPropCol("haxe.ui.heaps.engine.background.color");
        }
        _onReady();
    }

    private function onHeapsUpdate(dt:Float) {
        BackendImpl.update();
    }
    
    private var _onReady:Void->Void;
    private override function init(onReady:Void->Void, onEnd:Void->Void = null) {
        _onReady = onReady;
    }
    
    private override function getToolkitInit():ToolkitOptions {
        return {
            root: _app.s2d,
            manualUpdate: true
        };
    }
}