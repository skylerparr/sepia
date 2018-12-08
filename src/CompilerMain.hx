package ;

import comp.CPPIACompiler;
import logging.LogLevels;
import logging.Logger;
import logging.TraceLogger;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.Process;
class CompilerMain {
  public static function main() {
    setLogger();
    new CompilerMain();
  }

  private static var _consoleTrace: Dynamic;

  public static function setLogger() {
    _consoleTrace = haxe.Log.trace;
    haxe.Log.trace = myTrace;
  }

  private static function myTrace(v: Dynamic, ?inf: haxe.PosInfos): Void {
    _consoleTrace(v, inf);
  }

  public function new() {
    TraceLogger.logLevel = LogLevels.DEBUG;
    var logger = new TraceLogger();

    var builder = new CPPIACompiler();
    var exitCode = builder.compileAll("./scripts");
    if(exitCode == 1) {
      logger.error("Build failed");
    }
    Sys.exit(exitCode);
  }


}