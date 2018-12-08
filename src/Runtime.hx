package ;

import comp.CPPIACompiler;
import cpp.vm.Thread;
import ihx.HScriptEval;
import ihx.IHx;
import sys.FileSystem;
import core.ObjectFactory;
import haxe.ds.ObjectMap;
import sys.io.File;
import cpp.cppia.Module;
class Runtime {
  public static function main() {
    trace("starting runtime");
    new ObjectFactory();

    load();

//    var script: String = "out/Main.cppia";
//    var code: String = File.getContent(script);
//    var module: Module = Module.fromString(code);
//
//    module.run();

    var term: Thread = Thread.create(function() {
      IHx.main();
    });

    HScriptEval.interp.variables.set("c", compile);

    Thread.readMessage(true);
  }

  private static function compile(path: String): Void {
    var compiler = new CPPIACompiler();
    compiler.compileAll(path);

    load();
  }

  private static inline function load(): Void {
    var path: String = "./out/";
    var files: Array<String> = FileSystem.readDirectory(path);

    for(file in files) {
      var filePath: String = '${path}${file}';
      var code: String = File.getContent(filePath);
      var module: Module = Module.fromString(code);
      module.boot();
    }
  }
}