package ;

import sys.FileSystem;
import core.ObjectFactory;
import haxe.ds.ObjectMap;
import sys.io.File;
import cpp.cppia.Module;
class Runtime {
  public static function main() {
    trace("starting runtime");
    new ObjectFactory();

    var path: String = "./out/";
    var files: Array<String> = FileSystem.readDirectory(path);

    for(file in files) {
      var filePath: String = '${path}${file}';
      var code: String = File.getContent(filePath);
      var module: Module = Module.fromString(code);
      module.boot();
    }

    var script: String = "out/Main.cppia";
    var code: String = File.getContent(script);
    var module: Module = Module.fromString(code);

    module.run();
  }
}