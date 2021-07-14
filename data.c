#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

void color_table(int c, int w, int h)
{
   int p;
   printf("\nd_color_table_%x:", c);
   for (p = 0; p < w * h / 2; p += 2) {
      if (p % 24 == 0) printf("\ndw ");
      printf("0x%04x,", c + (c << 4) + (c << 8) + (c << 12));
   }
}

typedef enum {
   MAP_LINE = 1,
   MAP_DISK,
} map_prim;

typedef struct {
   map_prim type;
   int x0;              // line, disk
   int y0;              // line, disk
   int x1;              // line
   int y1;              // line
   double radius;       // disk
} map_prim_data;

static const map_prim_data g_map[] = {
   // Lines delimiting map square
   { MAP_LINE, 1, 1, 15, 1, 0.0 },
   { MAP_LINE, 15, 1, 15, 15, 0.0 },
   { MAP_LINE, 15, 15, 1, 15, 0.0 },
   { MAP_LINE, 1, 15, 1, 1, 0.0 },
   // Line from (2,8) to (8,2)
   //{ MAP_LINE, 2, 8, 8, 2, 0.0 },
   //{ MAP_LINE, 3, 8, 9, 2, 0.0 },
   // Disk at (12,12) radius (1.5)
   { MAP_DISK, 12, 12, 0, 0, 1.5 },
};

void map_trace_line(uint8_t *m, int w, int h, int x0, int y0, int x1, int y1)
{
   int dx = abs(x1 - x0);
   int sx = x0 < x1 ? 1 : -1;
   int dy = -abs(y1 - y0);
   int sy = y0 < y1 ? 1 : -1;
   int err = dx + dy;
   int x = x0, y = y0;
   while (1) {
      int err2 = 2*err;
      m[y * w + x] = 1;
      if (x == x1 && y == y1)
         break;
      if (err2 >= dy) {
         err += dy;
         x += sx;
      }
      if (err2 <= dx) {
         err += dx;
         y += sy;
      }
   }
}

void map_trace_disk(uint8_t *m, int w, int h, int x0, int y0, double radius)
{
   int x, y;
   for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) {
         if ((x - x0)*(x - x0) + (y - y0)*(y - y0) < radius*radius) {
            m[w * y + x] = 1;
         }
      }
   }
}

void map(int w, int h, int q)
{
   int p;
   int wb = w << q;
   int hb = h << q;
   size_t num_prims = sizeof(g_map) / sizeof(g_map[0]);
   uint8_t *m = calloc(wb * hb, 1);
   uint8_t *mp;
   int poffs;

   for (p = 0; p < num_prims; p++) {
      map_prim_data d = g_map[p];
      if (d.type == MAP_LINE) {
         map_trace_line(m, wb, hb, d.x0 << q, d.y0 << q, d.x1 << q, d.y1 << q);
      } else if (d.type == MAP_DISK) {
         map_trace_disk(m, wb, hb, d.x0 << q, d.y0 << q, d.radius * pow(2, q));
      }
   }
   // Print an ASCII preview in comments
   for (mp = m, poffs = 0; poffs < wb*hb; mp += 2, poffs += 2) {
      if (poffs % 128 == 0) printf("\n; ");
      printf("%c%c", *mp ? 35 : ' ', *(mp + 1) ? 35 : ' ');
   }
   printf("\nd_map:");
   for (mp = m, poffs = 0; poffs < wb*hb; mp += 2, poffs += 2) {
      if (poffs % 24 == 0) printf("\ndw ");
      printf("0x%04x,", *mp + (*(mp + 1) << 8));
   }

   free(m);
}

int main(int argc, char **argv)
{
   int i;
   for (i = 0; i < 16; i++) {
      color_table(i, 4, 240);
   }
   map(16, 16, 3);
   return 0;
}
