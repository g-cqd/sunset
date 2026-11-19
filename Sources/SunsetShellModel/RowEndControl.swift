/// One of a row's end controls besides its close button.
package enum RowEndControl: Hashable {
    case awake
    case sound(PaneSound)
    case device(PaneCapture.Device, PaneCapture.State)
}
