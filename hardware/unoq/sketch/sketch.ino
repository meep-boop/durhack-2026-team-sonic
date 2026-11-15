// Runs on the UNO Q's microcontroller. Shows the rig's verdict for the current step on the board's own LED matrix:
// a tick when the step is done right, a cross when it's wrong, blank otherwise. python/main.py calls show_verdict
// through the Bridge. Same calls as Arduino's LED Matrix Painter example (app-bricks-examples).
#include <Arduino_RouterBridge.h>
#include <Arduino_LED_Matrix.h>

Arduino_LED_Matrix matrix;

const int WIDTH = 13;
const int HEIGHT = 8;

// Drawn as text so the shapes can be read and edited here. If they show up scrambled on the board, the library
// lays its pixels out column by column, not row by row as assumed below.
const char *const TICK_ROWS[HEIGHT] = {
  "..........#..",
  ".........##..",
  "........##...",
  "..#....##....",
  "..##..##.....",
  "...####......",
  "....##.......",
  ".............",
};
const char *const CROSS_ROWS[HEIGHT] = {
  "...#.....#...",
  "....#...#....",
  ".....#.#.....",
  "......#......",
  ".....#.#.....",
  "....#...#....",
  "...#.....#...",
  ".............",
};

uint8_t tick[WIDTH * HEIGHT];
uint8_t cross[WIDTH * HEIGHT];
uint8_t blank[WIDTH * HEIGHT];

void fill(uint8_t *frame, const char *const rows[HEIGHT]) {
  for (int y = 0; y < HEIGHT; y++) {
    for (int x = 0; x < WIDTH; x++) frame[y * WIDTH + x] = rows[y][x] == '#' ? 255 : 0;
  }
}

// 0 blank, 1 tick, 2 cross: the codes in python/main.py. No Bridge calls in here: starting one while answering
// another can deadlock the Bridge.
void show_verdict(int verdict) {
  matrix.draw(verdict == 1 ? tick : verdict == 2 ? cross : blank);
}

void setup() {
  fill(tick, TICK_ROWS);
  fill(cross, CROSS_ROWS);
  matrix.begin();
  // 8-bit grayscale, so 255 is full brightness, as in Arduino's example.
  matrix.setGrayscaleBits(8);
  matrix.clear();
  Bridge.begin();
  Bridge.provide("show_verdict", show_verdict);
}

void loop() {
  delay(200);
}
