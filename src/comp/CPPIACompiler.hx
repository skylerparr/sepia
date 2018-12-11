package comp;
import sys.io.File;
import logging.LogLevels;
import logging.TraceLogger;
import logging.Logger;
import haxe.io.Bytes;
import sys.io.Process;
import sys.FileSystem;
class CPPIACompiler {
  private static var logger: Logger;

  private var classPath: String;
  private var additionlClassPaths: Array<String>;
  private var outputDir: String;

  public function new() {
    TraceLogger.logLevel = LogLevels.INFO;
    logger = new TraceLogger();
  }

  public function clean(path: String): Int {
    var toDelete: Array<String> = FileSystem.readDirectory(path);
    for(file in toDelete) {
      trace(toDelete);
    }
    return 0;
  }

  public function compileAll(path: String, out: String, classPaths: Array<String> = null): Int {
    classPath = path + "/";
    outputDir = out;

    if(classPaths == null) {
      classPaths = [];
    }

    this.additionlClassPaths = [];
    for(cp in classPaths) {
      additionlClassPaths.push("-cp");
      additionlClassPaths.push(cp);
    }
    logger.debug('classPath: ${classPath}');

    FileSystem.createDirectory(outputDir);

    var exitCode: Int = doCompileAll(path);

    return exitCode;
  }

  private function doCompileAll(path: String): Int {
    var exitCode: Int = 0;
    var scriptsToCompile: Array<String> = FileSystem.readDirectory(path);
    for (script in scriptsToCompile) {
      var relPath: String = path + '/' + script;
      logger.debug("relative path: " + relPath);
      var fullPath: String = FileSystem.absolutePath(relPath);
      logger.debug(fullPath);
      logger.debug(FileSystem.isDirectory(fullPath) + "");
      if(FileSystem.isDirectory(fullPath)) {
        exitCode = doCompileAll(relPath);
      } else {
        var scriptPath: String = StringTools.replace(relPath, classPath, "");
        logger.debug('Path args: ${scriptPath}');
        exitCode = compileFile('${scriptPath}');
      }
      if(exitCode == 1) {
        return 1;
      }
    }
    return exitCode;
  }

  public function compileFile(filename: String): Int {
    var filename: String = StringTools.replace(filename, ".hx", "");
    var mainName: String = StringTools.replace(filename, "/", ".");
    var filePath: String = '${outputDir}${mainName}.cppia';
    if (FileSystem.exists(filePath)) {
      FileSystem.deleteFile(filePath);
    }
    logger.info('${filePath}');
    var compileArgs: Array<String> =
    ["-main", mainName, "-cp", classPath, "-cppia", filePath];
    for(cp in additionlClassPaths) {
      compileArgs.push(cp);
    }

    logger.debug(compileArgs + "");
    var p: Process = new Process("haxe", compileArgs);
    var stdout = p.stderr;
    var output: Bytes = stdout.readAll();
    var exitCode = p.exitCode(true);
    if (exitCode == 1) {
      logger.warn(output.getString(0, output.length));
    }
    return exitCode;
  }
}
