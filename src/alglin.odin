package main

import "core:math"

Vec2 :: struct {
  x, y : f64
}

rotate_vec2 :: proc(v: Vec2, theta: f64) -> Vec2{
  c, s := math.cos(theta), math.sin(theta);
  return Vec2{v.x * c - v.y * s, v.x * s + v.y * c};
}

get_perpendicular_vec2 :: proc(v: Vec2) -> Vec2 {
  return Vec2{ -v.y, v.x };
}
