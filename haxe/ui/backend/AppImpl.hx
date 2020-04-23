package haxe.ui.backend;

private class HeapsApp extends hxd.App {
    public var onInit:Void->Void = null;
    public var onUpdate:Float->Void = null;
    
    private override function init() {
        super.init();
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
        hxd.Res.initLocal();
        #else
        hxd.Res.initEmbed();
        #end
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
            app: _app,
            manualUpdate: true
        };
    }
}