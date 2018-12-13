package ;

import core.CppiaObjectFactory;
import core.ScriptMacros;
import haxe.macro.Expr.Position;
import hscript.Parser;
import hscript.Interp;
import hscript.Macro;
import comp.CPPIACompiler;
import cpp.cppia.Module;
import ihx.HScriptEval;
import ihx.IHx;
import sys.FileSystem;
import sys.io.File;
class Runtime {

  private static var src: String;
  private static var output: String;
  private static var classPaths: Array<String>;
  private static var libs: Array<String>;

  public static function main(src: String, output: String, classPaths: Array<String>, libs: Array<String>) {
    ScriptMacros;
    CppiaObjectFactory;

    Runtime.src = src;
    Runtime.output = output;
    Runtime.classPaths = classPaths;
    Runtime.libs = libs;

    var variables = HScriptEval.interp.variables;

    variables.set("recompile", recompile);
    variables.set("r", recompile);
    variables.set("Type", Type);
    variables.set("Macro", hscript.Macro);
    variables.set("Parser", hscript.Parser);
    variables.set("Interp", hscript.Interp);

    var parser: Parser = new Parser();
    var interp: Interp = new Interp();
    var pos: Position = {file: "Runtime.hx", min: 0, max: 65535}
    var hscriptMacro: Macro = new Macro(pos);

    variables.set("eval", function(s: String): Dynamic {
      var ast = parser.parseString(s);
      return HScriptEval.interp.execute(ast);
    });

    variables.set("ast", function(s: String): Dynamic {
      return parser.parseString(s);
    });

    variables.set("macro", function(s: String): Dynamic {
      var ast = parser.parseString(s);
      return hscriptMacro.convert(ast);
    });

    IHx.main();
  }

  public static function recompile(): Array<String> {
    var compiler = new CPPIACompiler();
    var files: Array<String> = compiler.compileAll(src, output, classPaths, libs);

    load();
    reloadClasses(files);

    return files;
  }

  public static function reloadClasses(files: Array<String>): Void {
    var variables = HScriptEval.interp.variables;
    for(file in files) {
      var filename: String = StringTools.replace(file, ".hx", "");
      var pack: String = StringTools.replace(filename, "/", ".");
      var frags = pack.split(".");
      var className = frags[frags.length - 1];
      var clazz = Type.resolveClass(pack);
      if(clazz != null) {
        variables.set(className, clazz);
      }
    }
  }

  public static function load(): Array<String> {
    var path: String = output;
    var files: Array<String> = FileSystem.readDirectory(path);

    for(file in files) {
      var filePath: String = '${path}${file}';
      var code: String = File.getContent(filePath);
      var module: Module = Module.fromString(code);
      module.boot();
    }

    return files;
  }
}