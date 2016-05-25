import math
import random

import pyglet


class AttrBag:
    pass


window = pyglet.window.Window(fullscreen=True)
event_loop = pyglet.app.EventLoop()

FRAME_TIME = 1. / 60

BOX_X_MARGIN, BOX_Y_MARGIN = 100, 100
BOX_WIDTH = window.width - 2 * BOX_X_MARGIN
BOX_HEIGHT = window.height - 2 * BOX_Y_MARGIN
HORIZONTAL_SHIFT = window.width // 100


score = AttrBag()
score.points = 0

score_label = pyglet.text.Label(
    str(score.points),
    font_name='Comic Neue',
    font_size=BOX_Y_MARGIN // 2,
    x=window.width // 2, y=BOX_Y_MARGIN * 3 // 2 + BOX_HEIGHT,
    anchor_x='center', anchor_y='center')


palette = AttrBag()
palette.x, palette.y = window.width // 2, BOX_Y_MARGIN
palette.width = window.width // 20

ball = AttrBag()


def reset_ball():
    ball.x, ball.y = window.width // 2, window.height // 2

    v = min(window.width // 10, window.height // 10)
    phi = random.uniform(1 / 4 * math.pi, 3 / 4 * math.pi)

    ball.vx, ball.vy = v * math.cos(phi), -v * math.sin(phi)


reset_ball()


def draw_box():

    pyglet.graphics.draw(
        4, pyglet.gl.GL_LINE_STRIP,
        ('v2i', (
            BOX_X_MARGIN, BOX_Y_MARGIN,
            BOX_X_MARGIN, BOX_Y_MARGIN + BOX_HEIGHT,
            BOX_X_MARGIN + BOX_WIDTH, BOX_Y_MARGIN + BOX_HEIGHT,
            BOX_X_MARGIN + BOX_WIDTH, BOX_Y_MARGIN)))


def draw_palette():

    pyglet.graphics.draw(
        2, pyglet.gl.GL_LINE_STRIP,
        ('v2i', (
            palette.x - palette.width // 2, BOX_Y_MARGIN,
            palette.x + palette.width // 2, BOX_Y_MARGIN)))


def draw_ball():

    pyglet.graphics.draw(
        1, pyglet.gl.GL_POINTS,
        ('v2i', (ball.x, ball.y)))


def update(dt, _):
    dx, dy = round(ball.vx * FRAME_TIME), round(ball.vy * FRAME_TIME)

    if ball.x + dx <= BOX_X_MARGIN:
        x = BOX_X_MARGIN
        ball.vx = math.copysign(ball.vx, 1)
    elif BOX_X_MARGIN + BOX_WIDTH <= ball.x + dx:
        x = BOX_X_MARGIN + BOX_WIDTH
        ball.vx = math.copysign(ball.vy, -1)
    else:
        x = ball.x + dx

    if ball.y + dy <= BOX_Y_MARGIN:

        if palette.x - palette.width // 2 < ball.x + dx < palette.x + palette.width // 2:
            y = BOX_Y_MARGIN
            ball.vy = math.copysign(ball.vy, 1)
            score.points += 1
            score_label.text = str(score.points)

        else:
            score.points = 0
            score_label.text = str(score.points)
            reset_ball()
            return

    elif BOX_Y_MARGIN + BOX_HEIGHT <= ball.y + dy:
        y = BOX_Y_MARGIN + BOX_HEIGHT
        ball.vy = math.copysign(ball.vy, -1)
    else:
        y = ball.y + dy

    ball.x, ball.y = x, y


pyglet.clock.schedule(update, FRAME_TIME)


@window.event
def on_key_press(symbol, modifiers):
    if symbol == pyglet.window.key.ESCAPE:
        event_loop.exit()
    elif symbol == pyglet.window.key.LEFT:
        if BOX_X_MARGIN <= palette.x - palette.width // 2 - HORIZONTAL_SHIFT:
            palette.x -= HORIZONTAL_SHIFT
    elif symbol == pyglet.window.key.RIGHT:
        if palette.x + palette.width // 2 + HORIZONTAL_SHIFT <= window.width - BOX_X_MARGIN:
            palette.x += HORIZONTAL_SHIFT


@window.event
def on_draw():
    window.clear()
    score_label.draw()
    draw_box()
    draw_palette()
    draw_ball()


if __name__ == '__main__':
    event_loop.run()
