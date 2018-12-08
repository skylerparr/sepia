package;
import api.MasterFoo;
@:build(core.ScriptMacros.script())
class Foo implements MasterFoo {

  public function new() {
  }

  public function bar(): String {
    return "renewed bar";
  }
}