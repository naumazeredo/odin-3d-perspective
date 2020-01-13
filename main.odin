package test

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"
import "shared:io"

main :: proc() {
  sdl.init(sdl.Init_Flags.Everything);
  defer sdl.quit();

  window := sdl.create_window(
    "3D Perspective",
    i32(sdl.Window_Pos.Undefined),
    i32(sdl.Window_Pos.Undefined),
    800, 600,
    sdl.Window_Flags(0)
  );

  renderer := sdl.create_renderer(window, -1, sdl.Renderer_Flags(0));

  x, y := i32(100), i32(100);

  running := true;
  for running {
    e: sdl.Event;
    for sdl.poll_event(&e) != 0 {
      if e.type == sdl.Event_Type.Quit {
        running = false;
      }

      if e.type == sdl.Event_Type.Key_Down {
        if e.key.keysym.sym == sdl.SDLK_a { x -= 10; }
        if e.key.keysym.sym == sdl.SDLK_d { x += 10; }
        if e.key.keysym.sym == sdl.SDLK_w { y -= 10; }
        if e.key.keysym.sym == sdl.SDLK_s { y += 10; }
        //io.print("(%, %)\n", x, y);
      }
    }

    sdl.set_render_draw_color(renderer, 0, 0, 0, 255);
    sdl.render_clear(renderer);

    sdl.set_render_draw_color(renderer, 255, 255, 255, 255);
    pos_0 := sdl.Point{0, 0};
    pos_1 := sdl.Point{x, y};

    sdl.render_draw_line(renderer, pos_0.x, pos_0.y, pos_1.x, pos_1.y);

    sdl.render_present(renderer);
  }
}
