package test

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

import "core:math"

import "shared:io"


DIRECTION_LINE_SIZE :: 10;
PLAYER_MOV_SPEED :: 3;
PLAYER_ANG_SPEED :: math.PI/20;


Vec2 :: struct {
  x, y : f64
}

Player :: struct {
  pos : Vec2
  dir : Vec2
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

  renderer := sdl.create_renderer(window, -1, sdl.Renderer_Flags(0));

  // test region

  player := Player {
    pos = {100,100},
    dir = {1, 0}
  };

  // ------------

  running := true;
  for running {
    e: sdl.Event;
    for sdl.poll_event(&e) != 0 {
      if e.type == sdl.Event_Type.Quit {
        running = false;
      }

      if e.type == sdl.Event_Type.Key_Down {
        if e.key.keysym.sym == sdl.SDLK_a {
          player.dir = rotate_vec2(player.dir, -PLAYER_ANG_SPEED);
        }
        if e.key.keysym.sym == sdl.SDLK_d {
          player.dir = rotate_vec2(player.dir, PLAYER_ANG_SPEED);
        }
        if e.key.keysym.sym == sdl.SDLK_w {
          player.pos.x += player.dir.x * PLAYER_MOV_SPEED;
          player.pos.y += player.dir.y * PLAYER_MOV_SPEED;
        }
        if e.key.keysym.sym == sdl.SDLK_s {
          player.pos.x -= player.dir.x * PLAYER_MOV_SPEED;
          player.pos.y -= player.dir.y * PLAYER_MOV_SPEED;
        }
        if e.key.keysym.sym == sdl.SDLK_q {
          perp := get_perpendicular_vec2(player.dir);
          player.pos.x -= perp.x * PLAYER_MOV_SPEED;
          player.pos.y -= perp.y * PLAYER_MOV_SPEED;
        }
        if e.key.keysym.sym == sdl.SDLK_e {
          perp := get_perpendicular_vec2(player.dir);
          player.pos.x += perp.x * PLAYER_MOV_SPEED;
          player.pos.y += perp.y * PLAYER_MOV_SPEED;
        }
      }
    }

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
  }
}
