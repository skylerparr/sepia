package;

import core.ScriptMacros;
import core.CppiaObjectFactory;
import api.MasterFoo;
import api.MasterBar;

@:build(core.ScriptMacros.script())
class Bar implements MasterBar {

  public function new() {
    trace("new");
  }

  public function getFoo():MasterFoo {
    var f = new CppiaObjectFactory();
    var retVal = f.createInstance(MasterFoo);
    return retVal;
  }
}