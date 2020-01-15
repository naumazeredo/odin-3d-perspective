package main

import "core:math"
import "shared:io"

EPS :: 0.0001;

Vec2 :: struct {
  x, y : f64
}

Vec3 :: struct {
  x, y, z: f64
}

mul :: proc(v: Vec3, k: f64) -> Vec3 { return Vec3{k*v.x, k*v.y, k*v.z } };

to_vec3 :: proc(v: Vec2, z: f64 = 0) -> Vec3 { return Vec3{v.x, v.y, z}; }
to_vec2 :: proc(v: Vec3) -> Vec2 { return Vec2{v.x, v.y}; }

sub_vec2 :: proc(v1: Vec2, v2: Vec2) -> Vec2 { return Vec2{v1.x - v2.x, v1.y - v2.y}; }
sub_vec3 :: proc(v1: Vec3, v2: Vec3) -> Vec3 { return Vec3{v1.x - v2.x, v1.y - v2.y, v1.z - v2.z }; }
sub_vec  :: proc{sub_vec2, sub_vec3};

add_vec2 :: proc(v1: Vec2, v2: Vec2) -> Vec2 { return Vec2{v2.x + v1.x, v2.y + v1.y}; }
add_vec3 :: proc(v1: Vec3, v2: Vec3) -> Vec3 { return Vec3{v2.x + v1.x, v2.y + v1.y, v1.z + v2.z}; }
add_vec  :: proc{add_vec2, add_vec3};

rotate_vec2 :: proc(v: Vec2, theta: f64) -> Vec2 {
  c, s := math.cos(theta), math.sin(theta);
  return Vec2{v.x * c - v.y * s, v.x * s + v.y * c};
}

get_perpendicular_vec2 :: proc(v: Vec2) -> Vec2 { return Vec2{ -v.y, v.x }; }

world_to_camera2 :: proc(player: ^Player, point: Vec2) -> Vec2 {
  p := sub_vec(point, to_vec2(player.pos));
  theta := -math.atan2(player.dir.x, -player.dir.y);
  return rotate_vec2(p, theta);
}

world_to_camera3 :: proc(player: ^Player, point: Vec3) -> Vec3 {
  p := sub_vec(point, player.pos);
  theta := -math.atan2(player.dir.x, -player.dir.y);
  return to_vec3(rotate_vec2(to_vec2(p), theta), p.z);
}

world_to_camera :: proc{world_to_camera2, world_to_camera3};

camera_to_proj_point :: proc(point: Vec3) -> (Vec2, bool) {
  if point.y > -NEAR_PLANE { return Vec2{}, false; }

  p := mul(point, -NEAR_PLANE / point.y);
  asp := f64(VIEW_W)/f64(VIEW_H);

  x := (p.x + NEAR_PLANE)/(2*NEAR_PLANE);
  z := (p.z * asp - NEAR_PLANE)/(-2 * NEAR_PLANE);

  return Vec2{x, z}, true;
}

camera_to_proj_line :: proc(p1: Vec3, p2: Vec3) -> (Vec2, Vec2, bool) {
  if p1.y > -NEAR_PLANE && p2.y > -NEAR_PLANE { return Vec2{}, Vec2{}, false; }

  p1p, _ := camera_to_proj_point(p1);
  p2p, _ := camera_to_proj_point(p2);

  if p1.y <= -NEAR_PLANE && p2.y <= -NEAR_PLANE { return p1p, p2p, true; }

  v := sub_vec(p1, p2);
  v = mul(v, (-NEAR_PLANE - p1.y - EPS) / v.y);
  v = add_vec(p1, v);

  pn, ok := camera_to_proj_point(v);
  if !ok { io.print("error\n"); }

  if p1.y <= -NEAR_PLANE { return p1p, pn, true; }
  return pn, p2p, true;
}

camera_to_proj :: proc{camera_to_proj_point, camera_to_proj_line};

world_to_proj_point :: proc(player: ^Player, point: Vec3) -> (Vec2, bool) {
  return camera_to_proj(world_to_camera(player, point));
}

world_to_proj_line :: proc(player: ^Player, p1, p2 : Vec3) -> (Vec2, Vec2, bool) {
  return camera_to_proj(
    world_to_camera(player, p1),
    world_to_camera(player, p2)
  );
}

world_to_proj :: proc{world_to_proj_point, world_to_proj_line};
