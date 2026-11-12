import ApplicationServices
import Foundation

let usage = """
    axdrive: drive an app through accessibility, in the background (it is never brought to the front).

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
      axdrive wait PID QUERY [--timeout S] [--gone] [--role R] [--window W]
      axdrive shot PID FILE.png [--window W]           a picture of a window, behind others or not

    Exit: 0 done, 1 not found, 2 ambiguous (the candidates are printed; --pick N or --ask GOAL decide), 3 failed.
    """

let options = Options(CommandLine.arguments)
guard AXIsProcessTrusted() else {
    FileHandle.standardError.write(
        Data("axdrive: this terminal is not allowed to use accessibility (System Settings > Privacy)\n".utf8)
    )
    exit(3)
}
guard options.pid > 0 || options.command.isEmpty == false && options.pid > 0 else {
    print(usage)
    exit(options.command.isEmpty || options.command == "help" ? 0 : 3)
}
exit(await Commands.run(options))
