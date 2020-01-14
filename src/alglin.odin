package main

import "core:math"

Vec2 :: struct {
  x, y : f64
}

sub_vec2 :: proc(v1: Vec2, v2: Vec2) -> Vec2 {
  return Vec2{v1.x - v2.x, v1.y - v2.y};
}

add_vec2 :: proc(v1: Vec2, v2: Vec2) -> Vec2 {
  return Vec2{v2.x + v1.x, v2.y + v1.y};
}

rotate_vec2 :: proc(v: Vec2, theta: f64) -> Vec2 {
  c, s := math.cos(theta), math.sin(theta);
  return Vec2{v.x * c - v.y * s, v.x * s + v.y * c};
}

get_perpendicular_vec2 :: proc(v: Vec2) -> Vec2 {
  return Vec2{ -v.y, v.x };
}

world_to_camera :: proc(player: ^Player, point: Vec2) -> Vec2 {
  p := sub_vec2(point, player.pos);
  theta := -math.atan2(player.dir.x, -player.dir.y);
  return rotate_vec2(p, theta);
}
