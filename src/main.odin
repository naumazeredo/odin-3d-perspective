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

Player :: struct {
  pos : Vec2
  dir : Vec2
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

  renderer := sdl.create_renderer(window, -1, sdl.Renderer_Flags(0));

  // test region

  player := Player {
    pos = {100,100},
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

    sdl.set_render_draw_color(renderer, 0, 0, 0, 255);
    sdl.render_clear(renderer);

    sdl.set_render_draw_color(renderer, 255, 255, 255, 255);
    sdl.render_draw_line(
      renderer,
      i32(player.pos.x),
      i32(player.pos.y),
      i32(player.pos.x + player.dir.x * DIRECTION_LINE_SIZE),
      i32(player.pos.y + player.dir.y * DIRECTION_LINE_SIZE)
    );

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
    io.print("FPS: %\n", 1.0 / cur_frame_duration);

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
