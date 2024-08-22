package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

GameState :: struct {
    window_size: rl.Vector2,
    paddle: rl.Rectangle,
    ai_paddle: rl.Rectangle,
    paddle_speed: f32,
    ball: rl.Rectangle,
    ball_dir: rl.Vector2,
    ball_speed: f32,
}

reset :: proc(using gs: ^GameState) {
    angle := rand.float32_range(-45, 46)
    if rand.int_max(100) % 2 == 0 do angle += 180
    r := math.to_radians(angle)

    ball_dir.x = math.cos(r)
    ball_dir.y = math.sin(r)

    ball.x = window_size.x / 2 - ball.width / 2
    ball.y = window_size.y / 2 - ball.height / 2

    paddle_margin: f32 = 50

    paddle.x = window_size.x - (paddle.width + paddle_margin)
    paddle.y = window_size.y / 2 - paddle.height / 2

    ai_paddle.x = paddle_margin
    ai_paddle.y = window_size.y / 2 - paddle.height / 2
}

calculate_ball_direction :: proc(ball: rl.Rectangle, paddle: rl.Rectangle) -> (rl.Vector2, bool) {
        if (rl.CheckCollisionRecs(ball, paddle)) {
            ball_center := rl.Vector2 {
                ball.x + ball.width / 2,
                ball.y + ball.height / 2,
            }
            paddle_center := rl.Vector2{
                paddle.x + paddle.width / 2,
                paddle.y + paddle.height / 2,
            }
            return linalg.normalize0(ball_center - paddle_center), true
        }
    return {}, false
}
main :: proc() {
    gs := GameState {
        window_size = {1280, 720},
        paddle = {width = 30, height = 80},
        ai_paddle = {width = 30, height = 80},
        paddle_speed = 10,
        ball = {width = 30, height = 30},
        ball_speed = 10,
    }
    reset(&gs)

    using gs

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
        diff := ai_paddle.y + ai_paddle.height / 2 - ball.y + ball.height / 2
        if diff > 0 {
            ai_paddle.y -= paddle_speed
        }
        if diff < 0 {
            ai_paddle.y += paddle_speed
        }
        
        ai_paddle.y = linalg.clamp(ai_paddle.y, 0, window_size.y - ai_paddle.height)

        next_ball_rec := ball
        next_ball_rec.x += ball_speed * ball_dir.x
        next_ball_rec.y += ball_speed * ball_dir.y

        if (next_ball_rec.y + next_ball_rec.height) > 720 || next_ball_rec.y <= 0 {
            ball_dir.y *= -1
        }

        ball_dir = calculate_ball_direction(next_ball_rec, paddle) or_else ball_dir
        ball_dir = calculate_ball_direction(next_ball_rec, ai_paddle) or_else ball_dir

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
        rl.DrawRectangleRec(ai_paddle, rl.WHITE)
        rl.DrawRectangleRec(ball, rl.RED)
        // rl.DrawText(fmt.ctprintf("%v", pos), pos + 25, 55, 22, rl.WHITE)

        rl.EndDrawing()
    }
}