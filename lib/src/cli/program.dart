part of bridge.cli;

class BridgeCli extends Program {
  final Application app = new Application();
  final String _configPath;
  final List<String> _bootArguments;

  BridgeCli(List<String> this._bootArguments,
      String this._configPath,
      Shell shell) : super(shell) {
    app..singleton(this)..singleton(this, as: Program);
  }

  setUp() async {
    await app.setUp(_configPath);
    InputDevice.prompt = new Output('<cyan>=</cyan> ');
  }

  tearDown() async {
    await unwatch();
    await app.tearDown();
  }

  @override
  @Command('Exit and restart the program')
  reload([List<String> arguments = const []]) {
    return super.reload(_bootArguments..add(',')..addAll(arguments));
  }

  bool _watching = false;
  bool _reloading = false;
  StreamSubscription _watchSubscription;

  @Command('Watch your project files for changes')
  watch() async {
    if (_watching) {
      printWarning('Already watching!');
      return;
    }
    _watching = true;
    _watchSubscription =
        Directory.current.watch(recursive: true).listen((event) async {
          if (path.split(event.path).any((s) => s.startsWith('.'))) return;
          if (_reloading || path.basename(event.path).startsWith('.')) return;
          printAccomplishment('Reloading...');
          _reloading = true;
          await reload(_bootArguments.toString().contains('watch') ? [] : ['watch']);
        });
    printInfo('Watching files...');
  }

  @Command('Stop watching your project files for changes')
  unwatch() async {
    if (!_watching) return;
    await _watchSubscription.cancel();
    if (!_reloading)
      printInfo('Stopped watching files');
    _watching = false;
  }
}
