package project;

interface ProjectConfig {
  var applicationName: String;
  var srcPath: String;
  var outputPath: String;
  var classPaths: Array<String>;
  var libsPaths: Array<String>;
  var compilerArgs: Array<String>;
  var beforeCompileCallbacks: Array<Array<String>->Void>;
  var afterCompileCallbacks: Array<Array<String>->Void>;

  function subscribeBeforeCompileCallback(callback: Array<String>->Void): Void;
  function unsubscribeBeforeCompileCallback(callback: Array<String>->Void): Void;

  function subscribeAfterCompileCallback(callback: Array<String>->Void): Void;
  function unsubscribeAfterCompileCallback(callback: Array<String>->Void): Void;
}