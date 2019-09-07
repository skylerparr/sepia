package project;

class DefaultProjectConfig implements ProjectConfig {

  public var applicationName: String;
  public var srcPath: String;
  public var outputPath: String;
  public var classPaths: Array<String>;
  public var libsPaths: Array<String>;
  public var compilerArgs: Array<String>;

  public var beforeCompileCallbacks: Array<Array<String>->Void>;
  public var afterCompileCallbacks: Array<Array<String>->Void>;

  public function new(applicationName: String, srcPath: String, outputPath: String, classPaths: Array<String>, libsPaths: Array<String>) {
    this.applicationName = applicationName;
    this.srcPath = srcPath;
    this.outputPath = outputPath;
    this.classPaths = classPaths;
    this.libsPaths = libsPaths;

    beforeCompileCallbacks = [];
    afterCompileCallbacks = [];
  }

  public function subscribeBeforeCompileCallback(callback: Array<String> -> Void): Void {
    beforeCompileCallbacks.push(callback);
  }

  public function unsubscribeBeforeCompileCallback(callback: Array<String> -> Void): Void {
    beforeCompileCallbacks.remove(callback);
  }

  public function subscribeAfterCompileCallback(callback: Array<String> -> Void): Void {
    afterCompileCallbacks.push(callback);
  }

  public function unsubscribeAfterCompileCallback(callback: Array<String> -> Void): Void {
    afterCompileCallbacks.remove(callback);
  }

  public function toString(): String {
    return '{
  applicationName: ${applicationName},
  srcPath: ${srcPath},
  outputPath: ${outputPath},
  classPaths: ${classPaths},
  libsPaths: ${libsPaths},
  compilerArgs: ${compilerArgs},
}';
  }
}