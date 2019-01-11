package dirt;

import haxe.io.Bytes;
@:build(core.ScriptMacros.script())
class Earth {
  public static function getEarth(): String {
    trace("getting earth");
    return "earth";
  }

  public static function getBytes(): Bytes {
    return Bytes.alloc(1);
  }

  public function foo(): Void {
    trace('yay');
  }
}