package comp;
import util.PathUtil;
import haxe.crypto.Md5;
import haxe.Json;
import sys.io.File;
import logging.LogLevels;
import logging.TraceLogger;
import logging.Logger;
import haxe.io.Bytes;
import sys.io.Process;
import sys.FileSystem;
class CPPIACompiler {
  private static var logger: Logger;

  private static inline var cacheFile: String = "/tmp/build_cache.json";

  private var classPath: String;
  private var additionalClassPaths: Array<String>;
  private var outputDir: String;
  private var libs: Array<String>;

  public function new() {
    TraceLogger.logLevel = LogLevels.INFO;
    logger = new TraceLogger();
  }

  public function clean(path: String): Int {
    var toDelete: Array<String> = FileSystem.readDirectory(path);
    for(file in toDelete) {
      trace(file);
    }
    return 0;
  }

  public function getCache(): Dynamic {
    if(FileSystem.exists(cacheFile)) {
      var data: String = File.getContent(cacheFile);
      return Json.parse(data);
    } else {
      return {};
    }
  }

  public function saveCache(cache: Dynamic): Void {
    var data: String = Json.stringify(cache);
    File.saveContent(cacheFile, data);
  }

  public function compileAll(path: String, out: String, classPaths: Array<String> = null, usrlibs: Array<String> = null): Array<String> {
    classPath = path + "/";
    outputDir = out;

    if(classPaths == null) {
      classPaths = [];
    }

    this.additionalClassPaths = [];
    for(cp in classPaths) {
      additionalClassPaths.push("-cp");
      additionalClassPaths.push(cp);
    }
    logger.debug('classPath: ${classPath}');

    this.libs = [];
    for(lib in usrlibs) {
      libs.push("-lib");
      libs.push(lib);
    }
    logger.debug('libs: ${libs}');

    FileSystem.createDirectory(outputDir);

    var newFiles: Array<String> = [];
    doCompileAll(path, newFiles);

    return newFiles;
  }

  private function doCompileAll(path: String, newFiles: Array<String>): Int {
    var exitCode: Int = 0;
    var scriptsToCompile: Array<String> = FileSystem.readDirectory(path);
    for (script in scriptsToCompile) {
      var relPath: String = path + '/' + script;
      logger.debug("relative path: " + relPath);
      var fullPath: String = FileSystem.absolutePath(relPath);
      logger.debug(fullPath);
      logger.debug(FileSystem.isDirectory(fullPath) + "");
      if(FileSystem.isDirectory(fullPath)) {
        exitCode = doCompileAll(relPath, newFiles);
      } else {
        var scriptPath: String = StringTools.replace(relPath, classPath, "");
        logger.debug('full path: ${fullPath}');
        logger.debug('Path args: ${scriptPath}');

        if(unchanged(fullPath)) {
          continue;
        }

        newFiles.push(scriptPath);
        exitCode = compileFile(scriptPath);

        if(exitCode == 0) {
          var contents: String = File.getContent(fullPath);
          var contentsHash: String = Md5.encode(contents);
          var cache: Dynamic = getCache();
          Reflect.setField(cache, fullPath, contentsHash);
          saveCache(cache);
        }
      }
      if(exitCode == 1) {
        return 1;
      }
    }
    return exitCode;
  }

  public function compileFile(filename: String): Int {
    var mainName: String = PathUtil.getCPPIAPath(filename);
    var filePath: String = '${outputDir}${mainName}.cppia';
    if (FileSystem.exists(filePath)) {
      FileSystem.deleteFile(filePath);
    }
    logger.info('${filePath}');
    var compileArgs: Array<String> =
    ["-main", mainName, "-cp", classPath, "-cppia", filePath];
    for(cp in additionalClassPaths) {
      compileArgs.push(cp);
    }
    for(lib in libs) {
      compileArgs.push(lib);
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

  private function unchanged(path:String):Bool {
    var cache: Dynamic = getCache();
    var hash: String = Reflect.field(cache, path);
    var contents: String = File.getContent(path);
    var contentsHash: String = Md5.encode(contents);

    return hash == contentsHash;
  }
}
