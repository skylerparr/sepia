package core;

import haxe.ds.ObjectMap;
import api.MasterFoo;
import api.MasterBar;
class ObjectFactory {

  private static var classMap: ObjectMap<Dynamic, String>;

  public function new() {
    classMap = new ObjectMap<Dynamic, String>();
    classMap.set(MasterBar, "Bar");
    classMap.set(MasterFoo, "Foo");
  }

  public function createInstance(clazz:Class<Dynamic>, ?constructorArgs:Array<Dynamic>):Dynamic {
    if(constructorArgs == null) {
      constructorArgs = [];
    }
    var retVal = null;
    var className: String = classMap.get(clazz);
    var clazz = Type.resolveClass(className);
    retVal = Type.createInstance(clazz, []);

    return retVal;
  }
}