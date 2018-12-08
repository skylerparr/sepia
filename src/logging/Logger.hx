package logging;
interface Logger {
  function debug(message: Dynamic): Void;
  function info(message: Dynamic): Void;
  function warn(message: Dynamic): Void;
  function error(message: Dynamic): Void;
}
