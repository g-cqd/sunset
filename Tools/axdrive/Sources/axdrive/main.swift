import ApplicationServices
import Foundation

let usage = """
    axdrive: drive a test Sunset through accessibility, in the background (it is never brought to the front). Only a copy axdrive launched
    (AXDRIVE_TEST=1, configuration under /tmp/axdrive) is touched; any other process is refused (exit 4).

      axdrive launch [--config JSON|FILE] [--session FILE] [--binary PATH]    prints "PID FOLDER" once a window exists
      axdrive stop PID
      axdrive run PID < steps                          one step per line ("press OK --role button"), in one process; stops at a failure

      axdrive windows PID                              the app's windows (id, title, frame)
      axdrive tree PID [--window W] [--depth N]        the elements, indented by depth
      axdrive find PID QUERY [--role R] [--window W] [--menus] [--limit N]
                                                       ranked matches: tier (1 exact … 5 fuzzy), score, element
      axdrive press PID QUERY [--role R] [--window W] [--menus] [--pick N] [--ask GOAL] [--action AXPress]
      axdrive set PID QUERY VALUE [--role R] [--window W] [--confirm]     a field's value (then AXConfirm)
      axdrive focus PID QUERY [--role R] [--window W]
      axdrive main PID [TITLE]                         makes a window the app's main one (menus follow it), not brought forward
      axdrive menu PID "Menu>Item[>Sub]"               a menu bar item, pressed without opening the menu
      axdrive type PID TEXT                            characters to the process
      axdrive key PID CHORD                            "cmd+l", "return", "shift+cmd+t"
      axdrive scroll PID X Y DY                         turn the wheel over a window point (not seen by a WebKit page in the
                                                    background: use press … --action AXScrollToVisible there)
      Actions take --expect TEXT or --expect-gone TEXT [--expect-role R] [--timeout S]: the change is waited for, the action redone once
      when its target is still there; --within S waits for the target to appear and be enabled first (3 s).
      axdrive value PID QUERY TEXT                     the element's value holds TEXT (waited for)
      axdrive expect PID QUERY [--gone]                the same as wait
      axdrive wait PID QUERY [--timeout S] [--gone] [--role R] [--window W]
      axdrive shot PID FILE.png [--window W]           a picture of a window, behind others or not

    Exit: 0 done, 1 not found, 2 ambiguous (the candidates are printed; --pick N or --ask GOAL decide), 3 failed, 4 refused.
    """

let options = Options(CommandLine.arguments)
guard AXIsProcessTrusted() else {
    FileHandle.standardError.write(
        Data("axdrive: this terminal is not allowed to use accessibility (System Settings > Privacy)\n".utf8)
    )
    exit(3)
}
if options.command == "launch" {
    exit(await Launcher.launch(Options(["", "launch", "0"] + CommandLine.arguments.dropFirst(2))))
}
guard options.pid > 0 else {
    print(usage)
    exit(options.command.isEmpty || options.command == "help" ? 0 : 3)
}
guard Guard.allows(options.pid) else { exit(Launcher.refused(options.pid)) }
if options.command == "stop" { exit(Launcher.stop(options.pid)) }
if options.command == "run" { exit(await Runner.run(pid: options.pid)) }
exit(await Commands.run(options))
