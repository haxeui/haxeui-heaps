package haxe.ui.backend;

import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;
import haxe.ui.core.Platform;

using StringTools;

class OpenFileDialogImpl extends OpenFileDialogBase {
    #if hl
    
    public override function show() {
        if (Platform.instance.isWindows) {
            var title = options.title;
            if (title == null) {
                title = "Open File";
            }
            var file = hl.UI.loadFile({title: title });
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