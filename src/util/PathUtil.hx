package util;

class PathUtil {

  public static function getCPPIAPath(file: String): String {
    var filename: String = StringTools.replace(file, ".hx", "");
    var mainName: String = StringTools.replace(filename, "/", ".");
    return '${mainName}';
  }

  public static function cppiaToPath(cppiaFileName:String):String {
    cppiaFileName = StringTools.replace(cppiaFileName, ".", "/");
    cppiaFileName = StringTools.replace(cppiaFileName, "/cppia", ".hx");
    return cppiaFileName;
  }

}