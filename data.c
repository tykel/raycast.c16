#include <stdio.h>

void color_table(int c, int w, int h)
{
   int p;
   printf("\nd_color_table_%x:", c);
   for (p = 0; p < w * h / 2; p += 2) {
      if (p % 24 == 0) printf("\ndw ");
      printf("0x%04x,", c + (c << 4) + (c << 8) + (c << 12));
   }
}

int main(int argc, char **argv)
{
   int i;
   for (i = 0; i < 16; i++) {
      color_table(i, 4, 240);
   }
   return 0;
}
