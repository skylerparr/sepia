package ;

import api.MasterBar;
import core.CppiaObjectFactory;
import api.MasterFoo;

class Main {

  public static function main() {
    trace("hello world");
    var factory: CppiaObjectFactory = new CppiaObjectFactory();
    var foo: MasterBar = factory.createInstance(MasterBar);
    trace(foo.getFoo().bar());
  }

}