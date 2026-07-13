using Plank;

namespace Picky {
  public class PickyPreferences : DockItemPreferences {
    [Description(nick = "max-entries", blurb = "How many colors to keep")]
    public int MaxEntries { get; set; default = 10; }

    [Description(nick = "preview-size", blurb = "Size of preview window")]
    public int PreviewSize { get; set; default = 150; }

    [Description(nick = "format", blurb = "Color format, hex or rgb")]
    public string Format { get; set; default = "hex"; }

    [Description(nick = "swatch", blurb = "Show current color as swatch on the dock item")]
    public bool Swatch { get; set; default = false; }

    [Description(nick = "count", blurb = "Show number of picked colors as label on the dock item")]
    public bool Count { get; set; default = false; }

    public PickyPreferences.with_file(GLib.File file) {
      base.with_file(file);
    }

    protected override void reset_properties() {
      MaxEntries = 10;
      PreviewSize = 150;
      Format = "hex";
      Swatch = false;
      Count = false;
    }

    protected override void verify(string prop) {
      switch (prop) {
      case "MaxEntries":
        if (MaxEntries < 1) {
          MaxEntries = 1;
        }
        break;

      case "PreviewSize":
        // Keep in sync with the size limits enforced by ColorPreview
        if (PreviewSize < 20) {
          PreviewSize = 20;
        } else if (PreviewSize > 500) {
          PreviewSize = 500;
        }
        break;
      }
    }
  }
}
