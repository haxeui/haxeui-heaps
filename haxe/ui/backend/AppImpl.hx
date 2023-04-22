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
        _autoHandlePreload = false;
        _app = new HeapsApp();
        _app.onInit = onHeapsInit;
        _app.onUpdate = onHeapsUpdate;
    }
    
    private var _heapsInitialized:Bool = false;
    private var _heapsReadyCalled:Bool = false;
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
        _heapsInitialized = true;
        if (__onReady != null) {
            startPreload(function() {
                _heapsReadyCalled = true;
                __onReady();
            });
        }
    }

    private function onHeapsUpdate(dt:Float) {
        BackendImpl.update();
    }
    
    private var __onReady:Void->Void;
    private override function init(onReady:Void->Void, onEnd:Void->Void = null) {
        __onReady = onReady;
        if (_heapsInitialized == true && _heapsReadyCalled == false) {
            __onReady();
        }
    }
    
    private override function getToolkitInit():ToolkitOptions {
        return {
            root: _app.s2d,
            manualUpdate: true
        };
    }
}