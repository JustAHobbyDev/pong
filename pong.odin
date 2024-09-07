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
    ai_target_y: f32,
    ai_reaction_delay: f32,
    ai_reaction_timer: f32,
    score_player: int,
    score_cpu: int,
    boost_timer: f32,
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
        ai_reaction_delay = 0.1,
    }
    reset(&gs)

    using gs

    rl.InitWindow(i32(window_size.x), i32(window_size.y), "Pong")
    rl.SetTargetFPS(60)

    // Audio
    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()
    sfx_hit := rl.LoadSound("hit.wav")
    sfx_win := rl.LoadSound("win.wav")
    sfx_lose := rl.LoadSound("lose.wav")

    for !rl.WindowShouldClose() {
        // time
        delta := rl.GetFrameTime() 
        boost_timer -= delta

        if rl.IsKeyDown(.UP) {
            paddle.y -= 10
        }
        if rl.IsKeyDown(.DOWN) {
            paddle.y += 10
        }
        if rl.IsKeyPressed(.SPACE) {
            if boost_timer < 0 {
                boost_timer = 0.2
            }
        }

        paddle.y = linalg.clamp(paddle.y, 0, window_size.y - paddle.height)

        // AI Movement
        // increase timer by time between last frame and this one
        ai_reaction_timer += delta
        // if the timer is done:
        if ai_reaction_timer >= ai_reaction_delay {
            // reset the timer
            ai_reaction_timer = 0
            // use ball from last frame for extra delay
            ball_mid :=  ball.y + ball.height / 2
            // if the ball is heading left
            if ball_dir.x < 0 {
                // target the ball
                ai_target_y = ball_mid - ai_paddle.height / 2
                // add | subtract 0-20 to add inaccuracy
                ai_target_y += rand.float32_range(-20, 20)
            } else {
                ai_target_y = window_size.y / 2 - ai_paddle.height / 2
            }
        }

        // calculate the distance between paddle and target
        ai_paddle_mid := ai_paddle.y + ai_paddle.height / 2
        target_diff := ai_target_y - ai_paddle_mid
        // move either paddle_speed distance or less
        // won't bounce around so much
        ai_paddle.y += linalg.clamp(target_diff, -paddle_speed, paddle_speed) * 0.65
        // clamp to window_size
        ai_paddle.y = linalg.clamp(ai_paddle.y, 0, window_size.y - ai_paddle.height)

        // ball
        next_ball_rec := ball
        next_ball_rec.x += ball_speed * ball_dir.x
        next_ball_rec.y += ball_speed * ball_dir.y

        if (next_ball_rec.y + next_ball_rec.height) > 720 || next_ball_rec.y <= 0 {
            ball_dir.y *= -1
        }

        last_ball_dir := ball_dir
        new_dir, did_hit := calculate_ball_direction(next_ball_rec, paddle)
        if did_hit {
            // if <space> was pressed within the last 0.2 seconds
            if boost_timer > 0 {
                // boost_timer / 0.2 will give a percentage (ie. 30%)
                // we add 1 because we want to increase the speed (ie 130%)
                d := 1 + boost_timer / 0.2
                new_dir *= d
            }
            ball_dir = new_dir
        }
        ball_dir = calculate_ball_direction(next_ball_rec, ai_paddle) or_else ball_dir
        if last_ball_dir != ball_dir {
            rl.PlaySound(sfx_hit)
        }

        if next_ball_rec.x >= window_size.x - ball.width {
            score_cpu += 1
            rl.PlaySound(sfx_lose)
            reset(&gs)
        }
        if next_ball_rec.x < 0 {
            score_player += 1
            rl.PlaySound(sfx_win)
            reset(&gs)
        }

        ball.x += ball_speed * ball_dir.x
        ball.y += ball_speed * ball_dir.y

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawText(fmt.ctprintf("{}", score_cpu), 12, 12, 32, rl.WHITE)
        rl.DrawText(fmt.ctprintf("{}", score_player), i32(window_size.x) - 28, 12, 32, rl.WHITE)

        if boost_timer > 0 {
            rl.DrawRectangleRec(paddle, {u8(255 * (0.2 / boost_timer)), 255, 255, 255})
        } else {
            rl.DrawRectangleRec(paddle, rl.WHITE)
        }
        rl.DrawRectangleRec(ai_paddle, rl.WHITE)
        rl.DrawRectangleRec(ball, rl.RED)
        // rl.DrawText(fmt.ctprintf("%v", pos), pos + 25, 55, 22, rl.WHITE)

        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}