package ;

import api.MasterBar;
import core.ObjectFactory;
import api.MasterFoo;

class Main {

  public static function main() {
    trace("hello world");
    var factory: ObjectFactory = new ObjectFactory();
    var foo: MasterBar = factory.createInstance(MasterBar);
    trace(foo.getFoo().bar());
  }

}