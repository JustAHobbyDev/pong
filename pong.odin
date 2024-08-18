package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

GameState :: struct {
    window_size: rl.Vector2,
    paddle: rl.Rectangle,
    paddle_speed: f32,
    ball: rl.Rectangle,
    ball_dir: rl.Vector2,
    ball_speed: f32,
}

reset :: proc(using gs: ^GameState) {
    angle := rand.float32_range(-45, 46)
    r := math.to_radians(angle)

    ball_dir.x = math.cos(r)
    ball_dir.y = math.sin(r)

    ball.x = window_size.x / 2 - ball.width / 2
    ball.y = window_size.y / 2 - ball.height / 2

    paddle.x = window_size.x - 80
    paddle.y = window_size.y / 2 - paddle.height / 2
}

main :: proc() {
    gs := GameState {
        window_size = {1280, 720},
        paddle = {width = 30, height = 80},
        paddle_speed = 10,
        ball = {width = 30, height = 30},
        ball_speed = 10,
    }
    reset(&gs)

    using gs
    // ball := rl.Rectangle{100, 150, 30, 30}
    // ball_dir := rl.Vector2{0, -1}
    // ball_speed : f32 = 10
    // pos : i32 = 10
    // pos2 : i32 = 150
    // ball_height : i32 = 30

    rl.InitWindow(i32(window_size.x), i32(window_size.y), "Pong")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        if rl.IsKeyDown(.UP) {
            paddle.y -= 10
        }
        if rl.IsKeyDown(.DOWN) {
            paddle.y += 10
        }

        paddle.y = linalg.clamp(paddle.y, 0, window_size.y - paddle.height)

        next_ball_rec := ball
        next_ball_rec.x += ball_speed * ball_dir.x
        next_ball_rec.y += ball_speed * ball_dir.y

        if (next_ball_rec.y + next_ball_rec.height) > 720 || next_ball_rec.y <= 0 {
            ball_dir.y *= -1
        }
        if (rl.CheckCollisionRecs(next_ball_rec, paddle)) {
            ball_center := rl.Vector2 {
                next_ball_rec.x + ball.width / 2,
                next_ball_rec.y + ball.height / 2,
            }
            paddle_center := rl.Vector2{
                paddle.x + paddle.width / 2,
                paddle.y + paddle.height / 2,
            }
            ball_dir = linalg.normalize0(ball_center - paddle_center)
        }

        if next_ball_rec.x >= window_size.x - ball.width {
            reset(&gs)
        }
        if next_ball_rec.x < 0 {
            reset(&gs)
        }

        ball.x += ball_speed * ball_dir.x
        ball.y += ball_speed * ball_dir.y

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawRectangleRec(paddle, rl.WHITE)
        rl.DrawRectangleRec(ball, rl.RED)
        // rl.DrawText(fmt.ctprintf("%v", pos), pos + 25, 55, 22, rl.WHITE)

        rl.EndDrawing()
    }
}