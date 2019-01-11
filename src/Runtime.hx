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
  public static var src(get, set):String;
  @:isVar
  public static var output(get, set):String;
  @:isVar
  public static var classPaths(get, set):Array<String>;
  @:isVar
  public static var libs(get, set):Array<String>;
  @:isVar
  public static var defines(get, set): Array<String>;

  private static var completeCallback: Array<String>->Void;

  static function get_src():String {
    return src;
  }

  static function set_src(value:String):String {
    return src = value;
  }

  static function get_output():String {
    return output;
  }

  static function set_output(value:String):String {
    return output = value;
  }

  static function get_classPaths():Array<String> {
    return classPaths;
  }

  static function set_classPaths(value:Array<String>):Array<String> {
    return classPaths = value;
  }

  static function get_libs():Array<String> {
    return libs;
  }

  static function set_libs(value:Array<String>):Array<String> {
    return libs = value;
  }

  static function get_defines():Array<String> {
    return defines;
  }

  static function set_defines(value:Array<String>):Array<String> {
    return defines = value;
  }

  public static function main():Void {
    start("scripts", "out/", ["src", "common"], ["hscript"], null);
  }

  public static function start(src: String, output: String, classPaths: Array<String>, libs: Array<String>, onComplete: Array<String>->Void) {
    ScriptMacros;
    CppiaObjectFactory;

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
    clean();
    var compiler = new CPPIACompiler();
    var files: Array<String> = compiler.compileAll(src, output, classPaths, libs);

    files = loadAll();

    if(completeCallback != null) {
      completeCallback(files);
    }

    return files;
  }

  public static function loadFile(file:String):Void {
    var filePath: String = '${output}${PathUtil.getCPPIAPath(file)}.cppia';
    var code: String = File.getContent(filePath);
    var module: Module = Module.fromString(code);
    module.run();

    var filename: String = StringTools.replace(file, ".hx", "");
    var pack: String = StringTools.replace(filename, "/", ".");
    var frags = pack.split(".");
    var className = frags[frags.length - 1];
    var clazz = Type.resolveClass(pack);
    if(clazz != null) {
      var variables = HScriptEval.interp.variables;
      variables.set(className, clazz);
    }
  }

  public static function loadAll(): Array<String> {
    var path: String = output;
    var files: Array<String> = FileSystem.readDirectory(path);
    var retVal: Array<String> = [];

    for(file in files) {
      if(StringTools.endsWith(file, ".cppia")) {
        var srcFile: String = PathUtil.cppiaToPath(file);
        retVal.push(srcFile);
        loadFile(srcFile);
      }
    }

    return retVal;
  }

  public static function clean(): Int {
    return new CPPIACompiler().clean(output);
  }
}