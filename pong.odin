package main

import rl "vendor:raylib"
import fmt "core:fmt"
import strconv "core:strconv"
import strings "core:strings"

GameState :: struct {
    window_size: rl.Vector2,
    paddle: rl.Rectangle,
    paddle_speed: f32,
    ball: rl.Rectangle,
    ball_dir: rl.Vector2,
    ball_speed: f32,
}

main :: proc() {
    paddle := rl.Rectangle{100, 100, 180, 30}
    ball := rl.Rectangle{100, 150, 30, 30}
    ball_dir := rl.Vector2{0, -1}
    ball_speed : f32 = 10
    pos : i32 = 10
    pos2 : i32 = 150
    ball_height : i32 = 30

    rl.InitWindow(1280, 720, "Pong")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        if rl.IsKeyDown(rl.KeyboardKey.A) {
            if paddle.x > 0 {
                paddle.x -= 10
            }
        }
        if rl.IsKeyDown(rl.KeyboardKey.D) {
            if paddle.x < (1280 - 180) {
                paddle.x += 10
            }
        }

        next_ball_rec := ball
        next_ball_rec.y += ball_speed * ball_dir.y

        if (next_ball_rec.y + next_ball_rec.height) > 720 || next_ball_rec.y <= 0 {
            ball_dir.y *= -1
        }
        if (rl.CheckCollisionRecs(next_ball_rec, paddle)) {
            ball_dir.y *= -1
        }

        ball.y += ball_speed * ball_dir.y

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawRectangleRec(paddle, rl.WHITE)
        rl.DrawRectangleRec(ball, rl.RED)
        rl.DrawText(fmt.ctprintf("%v", pos), pos + 25, 55, 22, rl.WHITE)

        rl.EndDrawing()
    }
}