/// One of a row's end controls besides its close button.
enum RowEndControl: Hashable {
    case awake
    case sound(PaneSound)
    case device(PaneCapture.Device, PaneCapture.State)
}
