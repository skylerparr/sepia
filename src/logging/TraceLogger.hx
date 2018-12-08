package logging;

import t9.util.ColorTraces;
class TraceLogger implements Logger {

  public static var logLevel:Int;

  public function new() {
  }

  public function debug(message:Dynamic):Void {
    if(logLevel <= LogLevels.DEBUG) {
      trace(message);
    }
  }

  public function info(message:Dynamic):Void {
    if(logLevel <= LogLevels.INFO) {
      ColorTraces.traceCyan(message);
    }
  }

  public function warn(message:Dynamic):Void {
    if(logLevel <= LogLevels.WARN) {
      ColorTraces.traceYellow(message);
    }
  }

  public function error(message:Dynamic):Void {
    if(logLevel <= LogLevels.ERROR) {
      ColorTraces.traceRed(message);
    }
  }
}
