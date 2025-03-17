using Gtk;
using Gdk;
using Cairo;

namespace Picky {
  public enum Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT
  }

  public class PickerWindow : Gtk.Window {
    protected Gdk.Window window;
    protected ColorPreview preview;
    protected ColorSpecType color_format;
    protected string color_string;
    protected Clipboard clipboard;
    protected Gdk.Display display;
    protected Gdk.Seat seat;
    protected Gdk.Device pointer;
    protected Gdk.Device keyboard;
    protected int preview_size;

    private int source_x;
    private int source_y;
    private bool has_source_position = false;

    public signal void picked(Color color_string);

    /**
     * Constructor
     *
     * Constructs a window containing a color picker preview (ColorPreview)
     * and set up handlers for keyboard and mouse
     *
     * @param ColorSpecType type		The color format to use (HEX, RGB or X11NAME)
     * @param int			size			The size of the windo (square)
     */
    public PickerWindow(ColorSpecType type, int size) {
      Object(type: Gtk.WindowType.POPUP);

      color_format = type;
      preview_size = size;

      skip_pager_hint = true;
      skip_taskbar_hint = true;
      decorated = false;

      this.add_events(
                      EventMask.KEY_PRESS_MASK
                      | EventMask.SCROLL_MASK
                      | EventMask.POINTER_MOTION_MASK // Add motion event for updates
      );

      // Keyboard: SPACE BAR pick color (with SHIFT: keep picking, else pick & close)
      // ESC: Close picker window
      // F9/F10: Change window size (experimental)
      this.key_press_event.connect((event_key) => {
        switch (event_key.keyval) {
          case Gdk.Key.space:
            pick();
            if ((Gdk.ModifierType.SHIFT_MASK & event_key.state) == 0) {
              close_picker();
            }
            break;
          case Gdk.Key.Return:
            pick();
            if ((Gdk.ModifierType.SHIFT_MASK & event_key.state) == 0) {
              close_picker();
            }
            break;
          case Gdk.Key.Escape:
            close_picker();
            break;
          case Gdk.Key.F9:
            preview.size -= 10;
            set_default_size(preview.size, preview.size);
            break;
          case Gdk.Key.F10:
            preview.size += 10;
            set_default_size(preview.size, preview.size);
            break;
          case Gdk.Key.Down:
            move_pointer(Direction.DOWN);
            break;
          case Gdk.Key.Up:
            move_pointer(Direction.UP);
            break;
          case Gdk.Key.Left:
            move_pointer(Direction.LEFT);
            break;
          case Gdk.Key.Right:
            move_pointer(Direction.RIGHT);
            break;
          case Gdk.Key.j:
            move_pointer(Direction.DOWN);
            break;
          case Gdk.Key.k:
            move_pointer(Direction.UP);
            break;
          case Gdk.Key.h:
            move_pointer(Direction.LEFT);
            break;
          case Gdk.Key.l:
            move_pointer(Direction.RIGHT);
            break;
          default:
            break;
        }
        return false;
      });

      // Mouse:	LEFT CLICK: pick and close
      // RIGHT CLICK: pick and keep window open
      // WHEEL UP/DOWN: Zoom preview in/out
      this.button_press_event.connect((event_button) => {
        if (event_button.type == EventType.BUTTON_PRESS) {
          switch (event_button.button) {
            case 1:
            default:
              pick();
              close_picker();
              break;
            case 3:
              pick();
              break;
          }
        }
        return true;
      });

      this.scroll_event.connect((event_scroll) => {
        if (event_scroll.direction == ScrollDirection.UP) {
          preview.scale_up();
        } else if (event_scroll.direction == ScrollDirection.DOWN) {
          preview.scale_down();
        }

        update_preview();

        return true;
      });

      // Add motion handler to update preview when mouse moves
      this.motion_notify_event.connect(() => {
        update_preview();
        return false;
      });

      preview = new ColorPreview();
      preview.size = preview_size;
      this.add(preview);

      window = Gdk.get_default_root_window();
      display = Display.get_default();

      seat = display.get_default_seat();
      pointer = seat.get_pointer();

      if (pointer == null) {
        error("Could not get pointer device");
      }

      keyboard = seat.get_keyboard();
      if (keyboard == null) {
        error("Could not get keyboard device");
      }

      clipboard = Gtk.Clipboard.get_for_display(display, Gdk.SELECTION_CLIPBOARD);

      update_preview();

      this.show_all();
    }

    /**
     * Store information about where the picker was opened from.
     * This is used to simulate the mouse event leaving the dock.
     */
    public void set_source_info(int x, int y) {
      this.source_x = x;
      this.source_y = y;
      has_source_position = true;
    }

    /**
     * Open (activate) the preview window/ color picker
     * Grabs the mouse pointer and keyboard
     *
     * @return void
     */
    public void open_picker() {
      var crosshair = new Gdk.Cursor.for_display(display, Gdk.CursorType.CROSSHAIR);

      // Position the window correctly before showing it
      update_preview();

      // Grab both devices through the seat API
      var status = seat.grab(
                             this.get_window(),
                             Gdk.SeatCapabilities.ALL,
                             false,
                             crosshair,
                             null,
                             null
      );

      if (status != Gdk.GrabStatus.SUCCESS) {
        warning("Failed to grab seat: %d", status);
      }

      this.show_all();

      // Position again after showing to ensure correct placement
      update_preview();
    }

    /**
     * Close picker and handle transition back to source
     */
    protected void close_picker() {
      // Get current position of the pointer
      int current_x, current_y;
      window.get_device_position(pointer, out current_x, out current_y, null);

      // Get the screen for the pointer warp
      Gdk.Screen screen = Gdk.Screen.get_default();

      // Ungrab and hide
      seat.ungrab();
      this.hide();

      if (has_source_position) {
        // First move to source position (simulate returning to dock)
        pointer.warp(screen, source_x, source_y);

        // Then back to current position (where the picker was closed)
        // Wait for the main loop to process events
        GLib.Idle.add(() => {
          pointer.warp(screen, current_x, current_y);
          return false;
        });
      }
    }

    /**
     * Copy current color to clipboard and emit "picked" signal
     *
     * @return void
     */
    protected void pick() {
      // Copy current color to clipboard
      clipboard.set_text(preview.color.get_string(color_format), -1);
      // Emit signal
      picked(preview.color);
    }

    /**
     * Updates the preview window's position depending on
     * the current mouse pointer position
     *
     * @return void
     */
    public void update_preview() {
      // Skip update if window is not visible
      if (!this.visible)return;

      // Update the preview
      preview.queue_draw();

      // Move window (track mouse position)
      int x, y, posX, posY, offset = preview.size / 2;

      window.get_device_position(pointer, out x, out y, null);
      posX = x + offset;
      posY = y + offset;

      // Get monitor geometry for current pointer position
      Gdk.Monitor monitor = display.get_monitor_at_point(x, y);
      Gdk.Rectangle monitor_geometry = monitor.get_geometry();

      // Adjust position to stay within monitor bounds
      if (posX + preview_size >= monitor_geometry.x + monitor_geometry.width) {
        posX = x - (offset + preview_size);
      }
      if (posY + preview_size >= monitor_geometry.y + monitor_geometry.height) {
        posY = y - (offset + preview_size);
      }

      move(posX, posY);
    }

    /**
     * Moves the mouse pointer (and thus the preview window)
     * one pixel in the given direction
     *
     * @param Picky.Direction dir		The direction to move
     * @return void
     */
    public void move_pointer(Direction dir) {
      int x, y;
      window.get_device_position(pointer, out x, out y, null);
      switch (dir) {
      case Direction.UP:
        y--;
        break;
      case Direction.DOWN:
        y++;
        break;
      case Direction.LEFT:
        x--;
        break;
      case Direction.RIGHT:
        x++;
        break;
      }

      // Correct method to warp the pointer
      pointer.warp(Gdk.Screen.get_default(), x, y);
    }
  }
}
