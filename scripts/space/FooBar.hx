package space;
import haxe.io.Bytes;
import dirt.Earth;
@:build(core.ScriptMacros.script())
class FooBar {
  public function new() {
  }

  public function test() {
    trace("successssssssssss!");
  }

  public static function askFoo(): String {
    trace("asking foo");
    return Foo.getFoo();
  }

  public static function getEarth(): String {
    return Earth.getEarth();
  }

  public static function getBytes(): Bytes {
    return Bytes.alloc(1);
  }

}
