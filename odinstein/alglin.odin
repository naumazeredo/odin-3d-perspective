// @Todo: create to_vec2_render = Vec4 v -> Vec2{v.x, v.z}

package main

import "core:math"
import "shared:io"

EPS :: 0.0001;

Vec2 :: struct {
  x, y : f64
}

Vec3 :: struct {
  x, y, z : f64
}

Vec4 :: struct {
  x, y, z, w : f64
}

Mat3 :: [3][3]f64;
Mat4 :: [4][4]f64;

IDENTITY_3 :: Mat3{
  { 1, 0, 0 },
  { 0, 1, 0 },
  { 0, 0, 1 }
};

IDENTITY_4 :: Mat4{
  { 1, 0, 0, 0 },
  { 0, 1, 0, 0 },
  { 0, 0, 1, 0 },
  { 0, 0, 0, 1 }
};

mul_m4_v4 :: proc(m: Mat4, v: Vec4) -> Vec4 {
  return Vec4{
    m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3] * v.w,
    m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3] * v.w,
    m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3] * v.w,
    m[3][0] * v.x + m[3][1] * v.y + m[3][2] * v.z + m[3][3] * v.w
  };
}

mul_m3_m3 :: proc(m1, m2: Mat3) -> Mat3 {
  r : Mat3 = ---;

  for i in 0..2 {
    for j in 0..2 {
      r[i][j] = m1[i][0] * m2[0][j] +
                m1[i][1] * m2[1][j] +
                m1[i][2] * m2[2][j];
    }
  }

  return r;
}

mul_m4_m4 :: proc(m1, m2: Mat4) -> Mat4 {
  r : Mat4 = ---;

  for i in 0..3 {
    for j in 0..3 {
      r[i][j] = m1[i][0] * m2[0][j] +
                m1[i][1] * m2[1][j] +
                m1[i][2] * m2[2][j] +
                m1[i][3] * m2[3][j];
    }
  }

  return r;
}

mul_v2_k :: proc(v: Vec2, k: f64) -> Vec2 { return Vec2{k*v.x, k*v.y } }
mul_v3_k :: proc(v: Vec3, k: f64) -> Vec3 { return Vec3{k*v.x, k*v.y, k*v.z } }
mul :: proc{mul_v2_k, mul_v3_k, mul_m4_v4, mul_m3_m3, mul_m4_m4};

vec2_to_vec3 :: proc(v: Vec2, z: f64 = 0) -> Vec3 { return Vec3{v.x, v.y, z}; }
vec4_to_vec3 :: proc(v: Vec4) -> Vec3 { return Vec3{v.x, v.y, v.z}; }
to_vec3 :: proc{vec2_to_vec3, vec4_to_vec3};

vec3_to_vec2 :: proc(v: Vec3) -> Vec2 { return Vec2{v.x, v.y}; }
vec4_to_vec2 :: proc(v: Vec4) -> Vec2 { return Vec2{v.x, v.y}; }
to_vec2 :: proc{vec3_to_vec2, vec4_to_vec2};

vec2_to_vec4 :: proc(v: Vec2, z: f64 = 0, w: f64 = 0) -> Vec4 { return Vec4{v.x, v.y, z, w}; }
vec3_to_vec4 :: proc(v: Vec3, w: f64 = 0) -> Vec4 { return Vec4{v.x, v.y, v.z, w}; }
to_vec4 :: proc{vec2_to_vec4, vec3_to_vec4};

sub_vec2 :: proc(v1, v2: Vec2) -> Vec2 { return Vec2{v1.x - v2.x, v1.y - v2.y}; }
sub_vec3 :: proc(v1, v2: Vec3) -> Vec3 { return Vec3{v1.x - v2.x, v1.y - v2.y, v1.z - v2.z }; }
sub_vec  :: proc{sub_vec2, sub_vec3};

add_vec2 :: proc(v1, v2: Vec2) -> Vec2 { return Vec2{v2.x + v1.x, v2.y + v1.y}; }
add_vec3 :: proc(v1, v2: Vec3) -> Vec3 { return Vec3{v2.x + v1.x, v2.y + v1.y, v1.z + v2.z}; }
add_vec  :: proc{add_vec2, add_vec3};

dot_vec3 :: proc(v1, v2: Vec3) -> f64 { return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z; }
dot_vec  :: proc{dot_vec3};

rotate_vec2 :: proc(v: Vec2, theta: f64) -> Vec2 {
  c, s := math.cos(theta), math.sin(theta);
  return Vec2{v.x * c - v.y * s, v.x * s + v.y * c};
}

get_perpendicular_vec2 :: proc(v: Vec2) -> Vec2 { return Vec2{ -v.y, v.x }; }

get_rot_matrix_x :: proc(tetha: f64) -> Mat3 {
  c, s := math.cos(tetha), math.sin(tetha);

  return Mat3{
    { 1, 0,  0 },
    { 0, c, -s },
    { 0, s,  c }
  };
}

get_rot_matrix_y :: proc(tetha: f64) -> Mat3 {
  c, s := math.cos(tetha), math.sin(tetha);

  return Mat3{
    {  c, 0, s },
    {  0, 1, 0 },
    { -s, 0, c }
  };
}

get_rot_matrix_z :: proc(tetha: f64) -> Mat3 {
  c, s := math.cos(tetha), math.sin(tetha);

  return Mat3{
    { c, -s, 0 },
    { s,  c, 0 },
    { 0,  0, 1 }
  };
}

get_rot_matrix :: proc(yaw, pitch, roll: f64) -> Mat3 {
  return mul(
    mul(
      get_rot_matrix_x(yaw),
      get_rot_matrix_y(pitch)
    ),
    get_rot_matrix_z(roll)
  );
}

// General function to get World-to-Camera matrix
get_world_to_camera_matrix_3d :: proc(yaw, pitch, roll: f64, trans: Vec3) -> Mat4 {
  // To calculate this we need to calculate the camera-to-world matrix and take its inverse
  // Luckily its inverse is simple:
  // C2W = [[R T], [0 1]]
  // W2C = [[Rt (-R0*T, -R1*T, -R2*T)t], [0 1]]

  r := get_rot_matrix(yaw, pitch, roll);
  return Mat4{
    { r[0][0], r[1][0], r[2][0], -dot_vec(Vec3{r[0][0], r[0][1], r[0][2]}, trans) },
    { r[0][1], r[1][1], r[2][1], -dot_vec(Vec3{r[1][0], r[1][1], r[1][2]}, trans) },
    { r[0][2], r[1][2], r[2][2], -dot_vec(Vec3{r[2][0], r[2][1], r[2][2]}, trans) },
    { 0, 0, 0, 1 }
  };
}

get_world_to_camera_matrix_wolf :: proc(dir: Vec2, pos: Vec3) -> Mat4 {
  // Player reference points to negative z axis, that's why this math is weird
  // If it pointed to positive z it would be atan2(x, y)
  r := get_rot_matrix_y(-math.atan2(dir.x, -dir.y));

  return Mat4{
    { r[0][0], r[1][0], r[2][0], -dot_vec(Vec3{r[0][0], r[1][0], r[2][0]}, pos) },
    { r[0][1], r[1][1], r[2][1], -dot_vec(Vec3{r[0][1], r[1][1], r[2][1]}, pos) },
    { r[0][2], r[1][2], r[2][2], -dot_vec(Vec3{r[0][2], r[1][2], r[2][2]}, pos) },
    { 0, 0, 0, 1 }
  };
}

/*
// @Todo: remove these 2D functions
world_to_camera2 :: proc(player: ^Player, point: Vec2) -> Vec2 {
  p := sub_vec(point, to_vec2(player.pos));

  // Player reference points to negative y axis, that's why this math is weird
  theta := -math.atan2(player.dir.x, -player.dir.y);
  return rotate_vec2(p, theta);
}

world_to_camera3 :: proc(player: ^Player, point: Vec3) -> Vec3 {
  p := sub_vec(point, player.pos);

  // Player reference points to negative y axis, that's why this math is weird
  theta := -math.atan2(player.dir.x, -player.dir.y);
  v := rotate_vec2(Vec2{p.x, p.z}, theta);
  return Vec3{v.x, p.y, v.y};
}

//world_to_camera :: proc{world_to_camera2, world_to_camera3};
world_to_camera :: proc{world_to_camera3};
*/

/*
// @Todo: remove these 2D functions
world_to_camera2_mat :: proc(player: ^Player, point: Vec2) -> Vec2 {
  w2c_mat := get_world_to_camera_matrix_wolf(player.dir, player.pos);
  v := mul(w2c_mat, Vec4{point.x, 0, point.y, 1});
  return Vec2{v.x, v.z};
}
*/

world_to_camera3_mat :: proc(player: ^Player, point: Vec3) -> Vec3 {
  w2c_mat := get_world_to_camera_matrix_wolf(player.dir, player.pos);
  return to_vec3(mul(w2c_mat, to_vec4(point, 1)));
}

camera_to_proj_point :: proc(point: Vec3) -> (Vec2, bool) {
  if point.z > -NEAR_PLANE { return Vec2{}, false; }

  p := mul(point, -NEAR_PLANE / point.z);
  asp := f64(VIEW_W)/f64(VIEW_H);

  x := (p.x + NEAR_PLANE)/(2*NEAR_PLANE);
  y := (p.y * asp - NEAR_PLANE)/(-2 * NEAR_PLANE);

  return Vec2{x, y}, true;
}

camera_to_proj_line :: proc(p1: Vec3, p2: Vec3) -> (Vec2, Vec2, bool) {
  if p1.z > -NEAR_PLANE && p2.z > -NEAR_PLANE { return Vec2{}, Vec2{}, false; }

  p1p, _ := camera_to_proj_point(p1);
  p2p, _ := camera_to_proj_point(p2);

  if p1.z <= -NEAR_PLANE && p2.z <= -NEAR_PLANE { return p1p, p2p, true; }

  v := sub_vec(p1, p2);
  v = mul(v, (-NEAR_PLANE - p1.z - EPS) / v.z);
  v = add_vec(p1, v);

  pn, ok := camera_to_proj_point(v);
  if !ok { io.print("error\n"); }

  if p1.z <= -NEAR_PLANE { return p1p, pn, true; }
  return pn, p2p, true;
}

camera_to_proj :: proc{camera_to_proj_point, camera_to_proj_line};

/*
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
*/

// @Todo: camera_to_proj, world_to_proj

world_to_proj_line_mat:: proc(player: ^Player, p1, p2: Vec3) -> (Vec2, Vec2, bool) {
  return camera_to_proj(
    world_to_camera3_mat(player, p1),
    world_to_camera3_mat(player, p2)
  );
}
