package;

import core.ScriptMacros;
import core.ObjectFactory;
import api.MasterFoo;
import api.MasterBar;

@:build(core.ScriptMacros.script())
class Bar implements MasterBar {

  public function new() {
  }

  public function getFoo():MasterFoo {
    var f = new ObjectFactory();
    var retVal = f.createInstance(MasterFoo);
    return retVal;
  }
}