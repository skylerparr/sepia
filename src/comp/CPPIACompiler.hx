package comp;
import haxe.Template;
import sys.thread.Thread;
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

  @:isVar
  private var cacheFile(get, never): String;

  function get_cacheFile(): String {
    return '${outputDir}.build_cache';
  }

  public var classPath: String;
  public var additionalClassPaths: Array<String>;
  public var outputDir: String;
  public var libs: Array<String>;
  public var applicationName: String;

  public var numThreads: Int = 1;

  private static var cache: Dynamic = null;

  public function new() {
    TraceLogger.logLevel = LogLevels.INFO;
    logger = new TraceLogger();
  }

  public function clean(path: String): Int {
    if(FileSystem.exists(path)) {
      var toDelete: Array<String> = FileSystem.readDirectory(path);
      for(file in toDelete) {
        FileSystem.deleteFile('${path}${file}');
      }
      if(FileSystem.exists(cacheFile)) {
        FileSystem.deleteFile(cacheFile);
      }
    }
    cache = null;
    return 0;
  }

  public function getCache(): Dynamic {
    if(cache != null) {
      return cache;
    }

    if(FileSystem.exists(cacheFile)) {
      var data: String = File.getContent(cacheFile);
      cache = Json.parse(data);
      return cache;
    } else {
      return {};
    }
  }

  public function saveCache(cache: Dynamic): Void {
    var data: String = Json.stringify(cache);
    File.saveContent(cacheFile, data);
  }

  public function compileAll(appName: String, path: String, out: String, classPaths: Array<String> = null, usrlibs: Array<String> = null): Array<String> {
    classPath = path + "/";
    outputDir = out;
    this.applicationName = '${appName}ClassIncludes';
    getCache();

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

    var filesToCompile: Array<CompilationPaths> = [];
    var classes: Array<String> = [];
    gatherFilesToCompile(path, filesToCompile, classes);

    filesToCompile = findDependencies(filesToCompile, classes);
    filesToCompile = filterUnique(filesToCompile);

    if(filesToCompile.length > 0) {
      clean(outputDir);
      filesToCompile = [];
      gatherFilesToCompile(path, filesToCompile, classes);
      logger.debug('filesToCompile: ${filesToCompile}');
      logger.info('compiling ${filesToCompile.length} files...');

      generateApplicationFile(filesToCompile);

//      var compiledFiles: Array<String> = doCompileAll([{scriptPath: '${applicationName}.hx', fullPath: '${classPath}${applicationName}.hx'}]);
      var compiledFiles: Array<String> = doCompileSync([{scriptPath: '${applicationName}.hx', fullPath: '${classPath}${applicationName}.hx'}]);
      FileSystem.deleteFile('${classPath}${applicationName}.hx');
      compiledFiles = filesToCompile.map(function(map: Dynamic): String {
        return map.scriptPath;
      });
      return compiledFiles;
    } else {
      logger.info('Up to date');
      return [];
    }
  }

  private var template: String = 'package;
class ::applicationName:: {
  public static function main() {}

  public static function classes(): Dynamic {
    return [::classes::];
  }
}
';

  private function generateApplicationFile(files: Array<CompilationPaths>): Void {
    var classes: Array<String> = [];
    for(file in files) {
      var filename: String = StringTools.replace(file.scriptPath, ".hx", "");
      var className: String = StringTools.replace(filename, "/", ".");
      classes.push(className);
    }
    var t: Template = new Template(template);
    var content: String = t.execute({applicationName: applicationName, classes: classes.join(',')});
    File.saveContent('${classPath}${applicationName}.hx', content);
  }

  private function gatherFilesToCompile(path: String, files: Array<CompilationPaths>, classes: Array<String>): Void {
    var filesToCompile: Array<String> = FileSystem.readDirectory(path);
    for (script in filesToCompile) {
      var relPath: String = path + '/' + script;
      logger.debug("relative path: " + relPath);
      var fullPath: String = FileSystem.absolutePath(relPath);
      logger.debug('fullPath: ${fullPath}');
      logger.debug("full path is directory? " + FileSystem.isDirectory(fullPath) + "");
      if(FileSystem.isDirectory(fullPath)) {
        gatherFilesToCompile(relPath, files, classes);
      } else {
        var scriptPath: String = StringTools.replace(relPath, classPath, "");
        logger.debug('full path: ${fullPath}');
        logger.debug('Path args: ${scriptPath}');

        var pack: String = StringTools.replace(scriptPath, ".hx", "");
        pack = StringTools.replace(pack, "/", ".");
        classes.push(pack);
        if(!unchanged(fullPath)) {
          files.push({scriptPath: scriptPath, fullPath: fullPath});
        }
      }
    }
  }

  private function findDependencies(files: Array<CompilationPaths>, classes: Array<String>): Array<CompilationPaths> {
    var retVal: Array<CompilationPaths> = [];
    for(file in files) {
      retVal.push(file);
      var contents: String = File.getContent(file.fullPath);
      for(classPack in classes) {
        var frags: Array<String> = classPack.split(".");
        var className: String = frags[frags.length - 1];
        var regex: EReg = new EReg('.${className}.', 'g');
        var match: Bool = regex.match(contents);
        if(match) {
          var scriptPath: String = StringTools.replace(classPack, ".", "/");
          scriptPath = '${scriptPath}.hx';
          var fullPath: String = FileSystem.absolutePath('${classPath}${scriptPath}');
          retVal.push({scriptPath: scriptPath, fullPath: fullPath});
        }
      }
    }
    return retVal;
  }

  private function filterUnique(inFiles: Array<CompilationPaths>): Array<CompilationPaths> {
    var retVal: Array<CompilationPaths> = [];
    for(file in inFiles) {
      if(!contains(retVal, file)) {
        retVal.push(file);
      }
    }
    return retVal;
  }

  private function contains(array: Array<CompilationPaths>, toFind: CompilationPaths): Bool {
    for(item in array) {
      if(item.scriptPath == toFind.scriptPath) {
        return true;
      }
    }
    return false;
  }

  private function doCompileAll(toCompile: Array<CompilationPaths>): Array<String> {
    var retVal: Array<String> = [];
    var groups: Array<Array<CompilationPaths>> = [];
    for(i in 0...numThreads) {
      groups.push([]);
    }
    var counter: Int = 0;
    for(item in toCompile) {
      var index: Int = (counter++) % numThreads;
      groups[index].push(item);
    }

    var mainThread: Thread = Thread.current();
    var threads: Array<Thread> = [];
    var counter: Int = 0;
    for(group in groups) {
      counter++;
      var t: Thread = Thread.create(function() {
        var sleepTime = (counter * 50 / 10000);
        Sys.sleep(sleepTime);
        var ret: Array<String> = doCompileSync(group);
        mainThread.sendMessage(ret);
      });
    }

    var groupResults: Array<Array<String>> = [];
    while(groupResults.length < numThreads) {
      var result: Array<String> = Thread.readMessage(true);
      groupResults.push(result);
    }

    for(groupResult in groupResults) {
      for(result in groupResult) {
        retVal.push(result);
      }
    }

    return retVal;
  }

  private function doCompileSync(toCompile: Array<CompilationPaths>): Array<String> {
    var exitCode: Int = 0;
    var retVal: Array<String> = [];
    for(script in toCompile) {
      switch(script) {
        case {scriptPath: scriptPath, fullPath: fullPath}:
          exitCode = compileFile(scriptPath);
          retVal.push(scriptPath);
          if(exitCode == 0) {
            var contents: String = File.getContent(fullPath);
            var contentsHash: String = Md5.encode(contents);
            var cache: Dynamic = getCache();
            Reflect.setField(cache, fullPath, contentsHash);
            saveCache(cache);
          }
        case _:
          logger.warn("Unable to match on datastructure");
          break;
      }

      if(exitCode == 1) {
        return retVal;
      }
    }
    return retVal;
  }

  public function compileFile(filename: String): Int {
    var mainName: String = PathUtil.getCPPIAPath(filename);
    var filePath: String = '${outputDir}${mainName}.cppia';
    if (FileSystem.exists(filePath)) {
      FileSystem.deleteFile(filePath);
    }
    logger.debug('CompileFile file path: ${filePath}');
    var compileArgs: Array<String> =
    ["-main", mainName, "-cp", classPath, "-cppia", filePath, '-D', 'scriptable', '-D', 'hscriptPos',
      "-debug"];
    for(cp in additionalClassPaths) {
      compileArgs.push(cp);
    }
    for(lib in libs) {
      compileArgs.push(lib);
    }

    logger.debug("Compiler Args: " + compileArgs + "");
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
