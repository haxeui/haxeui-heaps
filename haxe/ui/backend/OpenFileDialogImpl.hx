package haxe.ui.backend;

import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.core.Platform;

using StringTools;

class OpenFileDialogImpl extends OpenFileDialogBase {
    #if (heaps_android && hl)

    /**
     * Android has no path-shaped file dialog: the Storage Access Framework
     * returns a content:// URI that cannot be opened, so heaps-android imports
     * the document into private storage and hands back a real path. That path
     * outlives the file the user picked, which is what lets a caller keep it in
     * a recent-files list.
     *
     * `options.extensions` is deliberately ignored. SAF filters on the MIME
     * type the *provider* reports, and providers routinely report .epub as
     * application/octet-stream and .md as nothing at all, so a filter that
     * looked right would hide real files from the user with no explanation.
     * `options.multiple` is not supported either: one file comes back.
     */
    public override function show() {
        haxe.ui.backend.android.FileDialog.openToFile("*/*",
            haxe.ui.backend.android.FileDialog.DEFAULT_PICK_DIR,
            function(path:Null<String>, error:Null<String>) {
                if (error != null) {
                    // The dialog contract has only OK and CANCEL, so without
                    // this the user would see a picker close for no reason.
                    var title = options.title != null ? options.title : "Open File";
                    Dialogs.messageBox(error, title, MessageBoxType.TYPE_ERROR);
                    dialogCancelled();
                    return;
                }
                if (path == null) {
                    dialogCancelled();
                    return;
                }

                var info:SelectedFileInfo = {
                    name: haxe.io.Path.withoutDirectory(path),
                    fullPath: path,
                    isBinary: false
                };
                if (options.readContents == true) {
                    if (options.readAsBinary) {
                        info.isBinary = true;
                        info.bytes = sys.io.File.getBytes(path);
                    } else {
                        info.isBinary = false;
                        info.text = sys.io.File.getContent(path);
                    }
                }
                dialogConfirmed([info]);
            });
    }

    #elseif hl

    public override function show() {
        if (Platform.instance.isWindows) {
            var title = options.title;
            if (title == null) {
                title = "Open File";
            }
            var nativeOptions:hl.UI.FileOptions = { }
            nativeOptions.title = title;
            nativeOptions.filters = buildFilters();
            
            var allowTimeout = hxd.System.allowTimeout;
            hxd.System.allowTimeout = false;
            var file = hl.UI.loadFile(nativeOptions);
            hxd.System.allowTimeout = allowTimeout;
            if (file != null) {
                var infos:Array<SelectedFileInfo> = [];
                infos.push({
                    name: haxe.io.Path.withoutDirectory(file),
                    fullPath: file,
                    isBinary: false
                });
                
                if (options.readContents == true) {
                    for (info in infos) {
                        if (options.readAsBinary) {
                            info.isBinary = true;
                            info.bytes = sys.io.File.getBytes(info.fullPath);
                        } else {
                            info.isBinary = false;
                            info.text = sys.io.File.getContent(info.fullPath);
                        }
                    }
                }
                
                dialogConfirmed(infos);
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

    private var _fileSelector:haxe.ui.util.html5.FileSelector = new haxe.ui.util.html5.FileSelector();
    
    public override function show() {
        var readMode = haxe.ui.util.html5.FileSelector.ReadMode.None;
        if (options.readContents == true) {
            if (options.readAsBinary == false) {
                readMode = haxe.ui.util.html5.FileSelector.ReadMode.Text;
            } else {
                readMode = haxe.ui.util.html5.FileSelector.ReadMode.Binary;
            }
        }
        _fileSelector.selectFile(onFileSelected, readMode, options.multiple, options.extensions);
    }
    
    private function onFileSelected(cancelled:Bool, files:Array<SelectedFileInfo>) {
        if (cancelled == false) {
            dialogConfirmed(files);
        } else {
            dialogCancelled();
        }
    }
    
    #end
}