package ;

import hscript.Macro;
import hscript.Parser;
import hscript.Interp;
import comp.CPPIACompiler;
import core.CppiaObjectFactory;
import core.ScriptMacros;
import cpp.cppia.Module;
import haxe.macro.Expr.Position;
import ihx.HScriptEval;
import ihx.IHx;
import sys.FileSystem;
import sys.io.File;
import util.PathUtil;
class Runtime {
  @:isVar
  public static var applicationName(default, default): String;
  @:isVar
  public static var src(default, default):String;
  @:isVar
  public static var output(default, default):String;
  @:isVar
  public static var classPaths(default, default):Array<String>;
  @:isVar
  public static var libs(default, default):Array<String>;
  @:isVar
  public static var defines(default, default): Array<String>;

  private static var completeCallback: Array<String>->Void;

  public static function main():Void {
    start("Sepia", "scripts", "out/", ["src", "common"], ["hscript"], null);
  }

  public static function start(applicationName: String, src: String, output: String, classPaths: Array<String>, libs: Array<String>, onComplete: Array<String>->Void) {
    ScriptMacros;
    CppiaObjectFactory;

    Runtime.applicationName = applicationName;
    Runtime.src = src;
    Runtime.output = output;
    Runtime.classPaths = classPaths;
    Runtime.libs = libs;
    Runtime.completeCallback = onComplete;

    var variables = HScriptEval.interp.variables;

    variables.set("recompile", recompile);
    variables.set("r", recompile);
    variables.set("clean", clean);
    variables.set("Type", Type);
    variables.set("Reflect", Reflect);
    variables.set("Macro", hscript.Macro);
    variables.set("Parser", hscript.Parser);
    variables.set("Interp", hscript.Interp);

    var parser: Parser = new Parser();
    var interp: Interp = new Interp();
    var pos: Position = {file: null, min: 0, max: 12}
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

    recompile();
    loadAll();

    IHx.main();
  }

  public static function recompile(): Array<String> {
    var compiler = new CPPIACompiler();
    var files: Array<String> = compiler.compileAll(applicationName, src, output, classPaths, libs);

    loadAll();

    for(file in files) {
      loadFile(file);
    }

    if(completeCallback != null) {
      completeCallback(files);
    }

    return files;
  }

  public static function loadFile(file:String):Void {
    var filename: String = StringTools.replace(file, ".hx", "");
    var pack: String = StringTools.replace(filename, "/", ".");
    var frags = pack.split(".");
    var className = frags[frags.length - 1];
    var clazz = Type.resolveClass(pack);
    if(clazz != null) {
      if(Reflect.hasField(clazz, 'main')) {
        var func = Reflect.field(clazz, 'main');
        func();
      }
      var variables = HScriptEval.interp.variables;
      variables.set(className, clazz);
    }
  }

  public static function loadAll(): Array<String> {
    var filePath: String = '${output}${applicationName}.cppia';
    var code: String = File.getContent(filePath);
    var module: Module = Module.fromString(code);
    module.run();

    return ['${applicationName}.hx'];
  }

  public static function compile(file: String, onComplete: String->Void): Int {
    var compiler = new CPPIACompiler();
    compiler.classPath = src;
    compiler.outputDir = output;
    compiler.additionalClassPaths = classPaths;
    compiler.libs = libs;

    var result: Int = compiler.compileFile(file);
    if(result == 1) {
      loadAll();
      if(onComplete != null) {
        onComplete(file);
      }
      return 1;
    }
    return 0;
  }

  public static function clean(): Int {
    return new CPPIACompiler().clean(output);
  }
}