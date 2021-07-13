#include <inttypes.h>
#include <stdio.h>
#include <math.h>

void lut_sincos(int n, int q, int d)
{
   int i;
   double invd = 1.0 / (double)d;
   double fp_scalar = pow(2, q);
   printf("\nd_%s_div%d:", __FUNCTION__, d);
   for (i = 0; i < n; i++) {
      double a = invd * sin(i * (180.0/(n*invd)) * M_PI / 180.0);
      double b = invd * cos(i * (180.0/(n*invd)) * M_PI / 180.0);
      int16_t a_fp = (int16_t)(a * fp_scalar);
      int16_t b_fp = (int16_t)(b * fp_scalar);
      if (i % 6 == 0) printf("\ndw ");
      printf("0x%04hx,0x%04hx,", a_fp, b_fp);
   }
}

void lut_col2radoffs(int n, int q)
{
   int i;
   double midpoint = n * 0.5 * 0.5 * M_PI / 180.0;
   double fp_scalar = pow(2, q);
   printf("\nd_%s:", __FUNCTION__);
   for (i = 0; i < n; i++) {
      double a = i * 0.5 * M_PI / 180.0 - midpoint;
      int16_t a_fp = (int16_t)(a * fp_scalar);
      if (i % 12 == 0) printf("\ndw ");
      printf("0x%04hx,", a_fp);
   }
}

int main(int argc, char **argv)
{
   lut_sincos(1024, 11, 2);
   lut_sincos(1024, 11, 10);
   lut_col2radoffs(80, 13);
   return 0;
}
