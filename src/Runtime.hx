package ;

import core.ObjectFactory;
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

  public static function main(src: String, output: String, classPaths: Array<String>) {
    ScriptMacros;
    ObjectFactory;

    Runtime.src = src;
    Runtime.output = output;
    Runtime.classPaths = classPaths;

    var variables = HScriptEval.interp.variables;

    variables.set("recompile", recompile);
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

  private static function recompile(): Void {
    var compiler = new CPPIACompiler();
    compiler.compileAll(src, output, classPaths);

    load();
  }

  private static inline function load(): Void {
    var path: String = output;
    var files: Array<String> = FileSystem.readDirectory(path);

    for(file in files) {
      var filePath: String = '${path}${file}';
      var code: String = File.getContent(filePath);
      var module: Module = Module.fromString(code);
      module.boot();
    }
  }
}