package main

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

WALL_H :: 20;

NEAR_PLANE :: 10;
FOV :: math.PI/2;

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

Player :: struct {
  pos : Vec3
  dir : Vec2
}

Color3 :: struct {
  r, g, b : u8
}

Line :: struct {
  A: Vec2
  B: Vec2
}

Wall :: struct {
  using line: Line,
  h: f64
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
    pos = { VIEW_W / 2, VIEW_H / 2, 0 },
    dir = {0, -1}
  };

  wall := Wall {
    { Vec2{ VIEW_W/8*3, VIEW_H/4 }, Vec2{ VIEW_W/8*5, VIEW_H/4 } },
    WALL_H
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

    if player_action(keystate, sdl.Scancode.A) {
      player.dir = rotate_vec2(player.dir, -PLAYER_ANG_SPEED);
    }
    if player_action(keystate, sdl.Scancode.D) {
      player.dir = rotate_vec2(player.dir, PLAYER_ANG_SPEED);
    }
    if player_action(keystate, sdl.Scancode.W) {
      move_player(&player, &player.dir, PLAYER_MOV_SPEED);
    }
    if player_action(keystate, sdl.Scancode.S) {
      move_player(&player, &player.dir, -1 * PLAYER_MOV_SPEED);
    }
    if player_action(keystate, sdl.Scancode.Q) {
      perp := get_perpendicular_vec2(player.dir);
      move_player(&player, &perp, -1 * PLAYER_MOV_SPEED);
    }
    if player_action(keystate, sdl.Scancode.E) {
      perp := get_perpendicular_vec2(player.dir);
      move_player(&player, &perp, PLAYER_MOV_SPEED);
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

    // Draw line
    sdl.render_draw_line(
      renderer,
      i32(wall.A.x),
      i32(wall.A.y),
      i32(wall.B.x),
      i32(wall.B.y)
    );

    //
    // Viewport Top-Right: Player top view
    //

    viewport_rect = VIEWS[0][1];
    sdl.render_set_viewport(renderer, &viewport_rect);

    origin  := Vec2{VIEW_W / 2, VIEW_H / 2};
    forward := Vec2{0, -1};

    // Draw player
    sdl.set_render_draw_color(
      renderer,
      COLOR_PLAYER_LINE.r, COLOR_PLAYER_LINE.g, COLOR_PLAYER_LINE.b, 255
    );

    sdl.render_draw_line(
      renderer,
      i32(origin.x),
      i32(origin.y),
      i32(origin.x + forward.x * DIRECTION_LINE_SIZE),
      i32(origin.y + forward.y * DIRECTION_LINE_SIZE)
    );

    sdl.set_render_draw_color(
      renderer,
      COLOR_PLAYER.r, COLOR_PLAYER.g, COLOR_PLAYER.b, 255
    );

    sdl.render_draw_point(
      renderer,
      i32(origin.x), i32(origin.y)
    );

    // Draw wall
    line2 := Line{ 
      add_vec2(world_to_camera(&player, wall.A), origin),  
      add_vec2(world_to_camera(&player, wall.B), origin) 
    };
    
    sdl.render_draw_line(
      renderer,
      i32(line2.A.x),
      i32(line2.A.y),
      i32(line2.B.x),
      i32(line2.B.y)
    );

    //
    // Viewport Down-Left: Player perspective
    //

    viewport_rect = VIEWS[1][0];
    sdl.render_set_viewport(renderer, &viewport_rect);

    p00 := world_to_proj(&player, Vec3 { wall.A.x, wall.A.y, wall.h/2 });
    p01 := world_to_proj(&player, Vec3 { wall.B.x, wall.B.y, wall.h/2 });
    p10 := world_to_proj(&player, Vec3 { wall.A.x, wall.A.y, -wall.h/2 });
    p11 := world_to_proj(&player, Vec3 { wall.B.x, wall.B.y, -wall.h/2 });

    sdl.render_draw_point(
      renderer,
      i32(p00.x*VIEW_W), i32(p00.y*VIEW_H)
    );

    // Horizontal
    sdl.set_render_draw_color(renderer, VIEW_COLORS[0][0].r, VIEW_COLORS[0][0].g, VIEW_COLORS[0][0].b, 255);
    sdl.render_draw_line(
      renderer,
      i32(p00.x*VIEW_W), i32(p00.y*VIEW_H),
      i32(p01.x*VIEW_W), i32(p01.y*VIEW_H)
    );
    sdl.set_render_draw_color(renderer, VIEW_COLORS[0][1].r, VIEW_COLORS[0][1].g, VIEW_COLORS[0][1].b, 255);
    sdl.render_draw_line(
      renderer,
      i32(p10.x*VIEW_W), i32(p10.y*VIEW_H),
      i32(p11.x*VIEW_W), i32(p11.y*VIEW_H)
    );

    // Vertical
    sdl.set_render_draw_color(renderer, VIEW_COLORS[1][0].r, VIEW_COLORS[1][0].g, VIEW_COLORS[1][0].b, 255);
    sdl.render_draw_line(
      renderer,
      i32(p00.x*VIEW_W), i32(p00.y*VIEW_H),
      i32(p10.x*VIEW_W), i32(p10.y*VIEW_H)
    );
    sdl.set_render_draw_color(renderer, VIEW_COLORS[1][1].r, VIEW_COLORS[1][1].g, VIEW_COLORS[1][1].b, 255);
    sdl.render_draw_line(
      renderer,
      i32(p01.x*VIEW_W), i32(p01.y*VIEW_H),
      i32(p11.x*VIEW_W), i32(p11.y*VIEW_H)
    );

    

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

move_player :: proc(p: ^Player, dir: ^Vec2, amount: f64) {
  p.pos.x += dir.x * amount;
  p.pos.y += dir.y * amount;
}

player_action :: proc(keystate: ^u8, code: sdl.Scancode) -> bool {
  return mem.ptr_offset(keystate, int(code))^ != 0;
}
