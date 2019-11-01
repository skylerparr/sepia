package ;

import core.ScriptMacros;
import core.CppiaObjectFactory;
import project.DefaultProjectConfig;
import project.ProjectConfig;
import comp.CPPIACompiler;
import cpp.cppia.Module;
import ihx.HScriptEval;
import ihx.IHx;
import sys.io.File;
class Runtime {
  public static function main():Void {
    var project: ProjectConfig = new DefaultProjectConfig("Sepia", 'scripts', 'out', ['src'], ['hscript-plus']);
    compileProject(project);
    start();
  }

  public static function start() {
    ScriptMacros;
    CppiaObjectFactory;
    IHx.main();
  }

  public static function stop(): Void {
    IHx.stop();
  }

  public static function compileProject(project: ProjectConfig): Array<String> {
    //All this needs to happen or it'll fail to compile
    {
      var variables = HScriptEval.interp.variables;
      variables.set("Type", Type);
      variables.set("Reflect", Reflect);
      variables.set("Macro", hscript.Macro);
      variables.set("Parser", hscript.Parser);
      variables.set("Interp", hscript.Interp);
    }

    var applicationName: String = project.applicationName;
    var src: String = project.srcPath;
    var output: String = project.outputPath;
    var classPaths: Array<String> = project.classPaths;
    var libs: Array<String> = project.libsPaths;
    
    var compiler = new CPPIACompiler();
    var files: Array<String> = compiler.compileAll(applicationName, src, output, classPaths, libs);

    loadAll(project);

    for(file in files) {
      loadFile(file);
    }

    var afterCompileCallbacks: Array<Array<String>->Void> = project.afterCompileCallbacks;
    if(afterCompileCallbacks != null) {
      for(callback in afterCompileCallbacks) {
        callback(files);
      }
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

  public static function loadAll(project: ProjectConfig): Array<String> {
    var applicationName: String = project.applicationName;
    // FIXME: Adding the suffix 'ClassIncludes' is duplicated in the CPPIA compile. Neet to unify.
    var filePath: String = '${project.outputPath}${applicationName}ClassIncludes.cppia';

    if(!sys.FileSystem.exists(filePath)) {
      return [];
    }
    var code: String = File.getContent(filePath);
    var module: Module = Module.fromString(code);
    module.run();

    return ['${applicationName}.hx'];
  }

  public static function compile(file: String, onComplete: String->Void): Int {
    var compiler = new CPPIACompiler();
    compiler.classPath = "";
    compiler.outputDir = "";
    compiler.additionalClassPaths = [];
    compiler.libs = [];

    var result: Int = compiler.compileFile(file);
    if(result == 1) {
      var project: ProjectConfig = new DefaultProjectConfig("NONE", file, "", [], []);
      loadAll(project);
      if(onComplete != null) {
        onComplete(file);
      }
      return 1;
    }
    return 0;
  }

  public static function clean(project: ProjectConfig): Int {
    return new CPPIACompiler().clean(project.outputPath);
  }
}
