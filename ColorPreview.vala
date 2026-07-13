using Gtk;
using Gdk;
using Cairo;

namespace Picky {
  public class ColorPreview : Gtk.DrawingArea {
    public int size { get; set; default = 64; }
    public double scale { get; set; default = 4.0; }
    public double scaling_factor { get; set; default = 1.3333; }
    public double min_scale { get; set; default = 1.0; }
    public double max_scale { get; set; default = 16.0; }
    public Color color { get; set; }
    public ColorSpecType color_format { get; set; default = ColorSpecType.HEX; }
    private Gdk.Window root_window;
    private Gdk.Seat seat;

    public ColorPreview() {
      set_size_request(size, size);

      this.notify["size"].connect((s, p) => {
        if (size < 20) {
          size = 20;
        }
        if (size > 500) {
          size = 500;
        }
        set_size_request(size, size);
      });

      draw.connect(on_draw);

      root_window = Gdk.get_default_root_window();
      seat = Display.get_default().get_default_seat();
    }

    public void scale_up() {
      scale = double.min(scale * scaling_factor, max_scale);
    }

    public void scale_down() {
      scale = double.max(scale / scaling_factor, min_scale);
    }

    protected bool on_draw(Context ctx) {
      Gdk.Pixbuf tmp_pb, pb;
      Color fgcol;
      unowned uint8[] pixels;
      int x, y;
      string color_string;

      var pointer = seat.get_pointer();
      if (pointer == null) {
        return false;
      }
      root_window.get_device_position(pointer, out x, out y, null);

      // Grab the preview area once, centered on the pointer, and read the
      // picked color from the center pixel. Off-screen portions of the grab
      // come back as black padding; the center is always real screen content.
      int grab_size = int.max(1, (int) (size / scale));

      tmp_pb = Gdk.pixbuf_get_from_window(root_window, x - grab_size / 2, y - grab_size / 2, grab_size, grab_size);
      if (tmp_pb == null) {
        return false;
      }

      int center = grab_size / 2;
      pixels = tmp_pb.get_pixels();
      int offset = center * tmp_pb.rowstride + center * tmp_pb.get_n_channels();

      color = Color() {
        red = (double) pixels[offset] / 255,
        green = (double) pixels[offset + 1] / 255,
        blue = (double) pixels[offset + 2] / 255
      };
      color_string = color.get_string(color_format);
      fgcol = Color.from_bgcolor(color);

      pb = tmp_pb.scale_simple(size, size, InterpType.TILES);
      if (pb == null) {
        return false;
      }

      Gdk.cairo_set_source_pixbuf(ctx, pb, 0, 0);
      ctx.paint();

      ctx.set_line_width(1);
      ctx.set_tolerance(0.1);
      ctx.set_source_rgb(fgcol.red, fgcol.green, fgcol.blue);
      ctx.arc(size / 2, size / 2, 3, 0, 2 * Math.PI);
      ctx.stroke();

      ctx.rectangle(0, 0, size, size);
      ctx.stroke();
      ctx.set_source_rgb(0.2, 0.2, 0.2);
      ctx.rectangle(1, 1, size - 2, size - 2);
      ctx.stroke();

      ctx.set_source_rgb(color.red, color.green, color.blue);
      ctx.rectangle(2, size - 24, size - 4, 22);
      ctx.fill();

      ctx.set_source_rgb(fgcol.red, fgcol.green, fgcol.blue);
      ctx.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
      ctx.set_font_size(13);
      ctx.move_to(4, size - 8);
      ctx.show_text(color_string);

      return false;
    }
  }
}
