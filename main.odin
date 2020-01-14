package test

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

import "core:math"
import "core:mem"

import "shared:io"


DIRECTION_LINE_SIZE :: 10;
PLAYER_MOV_SPEED :: 3;
PLAYER_ANG_SPEED :: math.PI/20;

FRAMES_PER_SEC :: 60.0;
FRAME_DURATION_MS :: 1000.0 / FRAMES_PER_SEC;

WINDOW_WIDTH  :: 800;
WINDOW_HEIGHT :: 600;

VIEW_VSPACING :: 20;
VIEW_HSPACING :: 20;
VIEW_W :: (WINDOW_WIDTH  - 3 * VIEW_HSPACING) / 2;
VIEW_H :: (WINDOW_HEIGHT - 3 * VIEW_VSPACING) / 2;

VIEWS := [2][2]sdl.Rect {
  {
    sdl.Rect{
      VIEW_HSPACING, VIEW_VSPACING,
      VIEW_W, VIEW_H
    },
    sdl.Rect{
      2 * VIEW_HSPACING + VIEW_W, VIEW_VSPACING,
      VIEW_W, VIEW_H
    }
  },
  {
    sdl.Rect{
      VIEW_HSPACING, 2 * VIEW_VSPACING + VIEW_H,
      VIEW_W, VIEW_H
    },
    sdl.Rect{
      2 * VIEW_HSPACING + VIEW_W, 2 * VIEW_VSPACING + VIEW_H,
      VIEW_W, VIEW_H
    }
  }
};

VIEW_COLORS := [2][2]Color3 {
  { Color3{244, 78, 36}, Color3{129, 185, 0} },
  { Color3{1, 164, 239}, Color3{255, 185, 2} }
};

COLOR_PLAYER      :: Color3{255, 255, 255};
COLOR_PLAYER_LINE :: Color3{128, 128, 128};


Vec2 :: struct {
  x, y : f64
}

Player :: struct {
  pos : Vec2
  dir : Vec2
}

Color3 :: struct {
  r, g, b : u8
}

rotate_vec2 :: proc(v: Vec2, theta: f64) -> Vec2{
  c, s := math.cos(theta), math.sin(theta);
  return Vec2{v.x * c - v.y * s, v.x * s + v.y * c};
}

get_perpendicular_vec2 :: proc(v: Vec2) -> Vec2 {
  return Vec2{ -v.y, v.x };
}

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
  defer sdl.destroy_window(window);

  renderer := sdl.create_renderer(window, -1, sdl.Renderer_Flags(0));
  defer sdl.destroy_renderer(renderer);

  // test region

  player := Player {
    pos = {VIEW_W / 2, VIEW_H / 2},
    dir = {1, 0}
  };

  keystate := sdl.get_keyboard_state(nil);

  frame_time := sdl.get_performance_counter();

  // ------------

  running := true;
  for running {

    // Input handling

    e: sdl.Event;
    for sdl.poll_event(&e) != 0 {
      if e.type == sdl.Event_Type.Quit {
        running = false;
      }
    }

    sdl.pump_events();
    old_keystate := keystate;
    keystate = sdl.get_keyboard_state(nil);

    if mem.ptr_offset(keystate, int(sdl.Scancode.A))^ != 0 {
      player.dir = rotate_vec2(player.dir, -PLAYER_ANG_SPEED);
    }
    if mem.ptr_offset(keystate, int(sdl.Scancode.D))^ != 0 {
      player.dir = rotate_vec2(player.dir, PLAYER_ANG_SPEED);
    }
    if mem.ptr_offset(keystate, int(sdl.Scancode.W))^ != 0 {
      player.pos.x += player.dir.x * PLAYER_MOV_SPEED;
      player.pos.y += player.dir.y * PLAYER_MOV_SPEED;
    }
    if mem.ptr_offset(keystate, int(sdl.Scancode.S))^ != 0 {
      player.pos.x -= player.dir.x * PLAYER_MOV_SPEED;
      player.pos.y -= player.dir.y * PLAYER_MOV_SPEED;
    }
    if mem.ptr_offset(keystate, int(sdl.Scancode.Q))^ != 0 {
      perp := get_perpendicular_vec2(player.dir);
      player.pos.x -= perp.x * PLAYER_MOV_SPEED;
      player.pos.y -= perp.y * PLAYER_MOV_SPEED;
    }
    if mem.ptr_offset(keystate, int(sdl.Scancode.E))^ != 0 {
      perp := get_perpendicular_vec2(player.dir);
      player.pos.x += perp.x * PLAYER_MOV_SPEED;
      player.pos.y += perp.y * PLAYER_MOV_SPEED;
    }

    // ----

    // Render

    viewport_rect : sdl.Rect;

    // Window
    sdl.render_set_viewport(renderer, nil);
    sdl.set_render_draw_color(renderer, 0, 0, 0, 255);
    sdl.render_clear(renderer);

    for i in 0..1 {
      for j in 0..1 {
        viewport_rect = VIEWS[i][j];
        color := VIEW_COLORS[i][j];
        sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255);
        sdl.render_draw_rect(renderer, &viewport_rect);
      }
    }

    //
    // Viewport Top-Left: World top view
    //

    viewport_rect = VIEWS[0][0];
    sdl.render_set_viewport(renderer, &viewport_rect);

    // Draw player
    sdl.set_render_draw_color(
      renderer,
      COLOR_PLAYER_LINE.r, COLOR_PLAYER_LINE.g, COLOR_PLAYER_LINE.b, 255
    );

    sdl.render_draw_line(
      renderer,
      i32(player.pos.x),
      i32(player.pos.y),
      i32(player.pos.x + player.dir.x * DIRECTION_LINE_SIZE),
      i32(player.pos.y + player.dir.y * DIRECTION_LINE_SIZE)
    );

    sdl.set_render_draw_color(
      renderer,
      COLOR_PLAYER.r, COLOR_PLAYER.g, COLOR_PLAYER.b, 255
    );

    sdl.render_draw_point(
      renderer,
      i32(player.pos.x), i32(player.pos.y)
    );

    //
    // Viewport Top-Right: Player top view
    //

    //
    // Viewport Down-Left: Player perspective
    //

    //
    // Viewport Down-Right: Doom
    //

    // -----

    sdl.render_present(renderer);

    // Framerate capping

    new_frame_time := sdl.get_performance_counter();
    cur_frame_duration : f64 = 1000.0 * f64(new_frame_time - frame_time) / f64(sdl.get_performance_frequency());

    if cur_frame_duration < FRAME_DURATION_MS {
      delay_duration : u32 = auto_cast (FRAME_DURATION_MS - cur_frame_duration);
      sdl.delay(delay_duration);
    }

    // FPS calculation

    new_frame_time = sdl.get_performance_counter();
    cur_frame_duration = 1.0 * f64(new_frame_time - frame_time) / f64(sdl.get_performance_frequency());
    //io.print("FPS: %\n", 1.0 / cur_frame_duration);

    frame_time = sdl.get_performance_counter();

    // ----
  }
}
