package haxe.ui.backend;

import haxe.ui.core.Platform;

using StringTools;

class SaveFileDialogImpl extends SaveFileDialogBase {
    #if hl
    
    public override function show() {
        if (fileInfo == null || (fileInfo.text == null && fileInfo.bytes == null)) {
            throw "Nothing to write";
        }
        
        if (Platform.instance.isWindows) {
            var title = options.title;
            if (title == null) {
                title = "Save File";
            }
            var nativeOptions:hl.UI.FileOptions = { }
            nativeOptions.title = title;
            nativeOptions.fileName = fileInfo.name;
            nativeOptions.filters = buildFilters();
            
            var allowTimeout = hxd.System.allowTimeout;
            hxd.System.allowTimeout = false;
            var file = hl.UI.saveFile(nativeOptions);
            hxd.System.allowTimeout = allowTimeout;
            if (file != null) {
                var fullPath = file;
                if (fileInfo.text != null) {
                    sys.io.File.saveContent(fullPath, fileInfo.text);
                } else if (fileInfo.bytes != null) {
                    sys.io.File.saveBytes(fullPath, fileInfo.bytes);
                }
                dialogConfirmed();
            } else {
                dialogCancelled();
            }
        } else {
            super.show();
        }
    }
    
    
    private function buildFilters():Array<{name:String, exts:Array<String>}> {
        var filters = null;
        if (options.extensions != null) {
            filters = [];
            for (e in options.extensions) {
                var ext = e.extension;
                ext = ext.trim();
                if (ext.length == 0) {
                    continue;
                }
                var single = e.label;
                var parts = ext.split(",");
                var finalParts = [];
                for (p in parts) {
                    p = p.trim();
                    if (p.length == 0) {
                        continue;
                    }
                    finalParts.push(p);
                }
                single += " (" + finalParts.join(", ") + ")";
                filters.push({name: single, exts: finalParts});
            }
        }
        return filters;
    }
    
    #elseif js
    
    private var _fileSaver:haxe.ui.util.html5.FileSaver = new haxe.ui.util.html5.FileSaver();
    
    public override function show() {
        if (fileInfo == null || (fileInfo.text == null && fileInfo.bytes == null)) {
            throw "Nothing to write";
        }
        
        if (fileInfo.text != null) {
            _fileSaver.saveText(fileInfo.name, fileInfo.text, onSaveResult);
        } else if (fileInfo.bytes != null) {
            _fileSaver.saveBinary(fileInfo.name, fileInfo.bytes, onSaveResult);
        }
    }
    
    private function onSaveResult(r:Bool) {
        if (r == true) {
            dialogConfirmed();
        } else {
            dialogCancelled();
        }
    }
    
    #end
}