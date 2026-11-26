/// Where a frame is (ADR-0094, t103): fields are told from a frame only when its place in the page is known.
extension PasswordFillScript {
    /// `offset()`: where the frame's viewport is in the top one's, in CSS pixels; null when it or a frame above it is of
    /// another origin. Part of `watch`.
    static let frameOffset = """
        // A frame tells only when it and every frame above it are of one origin (ADR-0094): where its viewport is in
        // the top one's is then known. Another origin's frame (an ad, a sandboxed frame) is left alone.
        const offset = () => {
          let x = 0, y = 0;
          for (let w = window; w !== w.top; w = w.parent) {
            let el;
            try {
              el = w.frameElement;
              // The documents' origins (`origin`), not their addresses' (`location.origin`): a srcdoc or
              // about:blank frame has its parent's.
              if (!el || w.parent.origin !== self.origin || self.origin === 'null') return null;
            } catch { return null; }
            const r = el.getBoundingClientRect(), style = w.parent.getComputedStyle(el);
            x += r.left + el.clientLeft + parseFloat(style.paddingLeft);
            y += r.top + el.clientTop + parseFloat(style.paddingTop);
          }
          return { x, y };
        };
        """
}
