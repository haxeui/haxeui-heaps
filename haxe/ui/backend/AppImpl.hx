package haxe.ui.backend;

import haxe.ui.backend.heaps.HeapsApp;
import haxe.ui.core.Screen;
import haxe.ui.Preloader.PreloadItem;
import haxe.ui.util.ColorUtil;

class AppImpl extends AppBase {
    public function new() {
    }
    
    private override function init(onReady:Void->Void, onEnd:Void->Void = null) {
        var app:HeapsApp = Screen.instance.app;
        app.onInitialized = function() {
            Screen.instance.init();
            onReady();
        };
        app.engine.backgroundColor = ColorUtil.parseColor(Toolkit.backendProperties.getProp("haxe.ui.heaps.background.color", "0xFFFFFFFF"));
    }
}
