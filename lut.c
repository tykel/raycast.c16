#include <inttypes.h>
#include <stdio.h>
#include <math.h>

void lut_Nsincos(int n, int q)
{
   int i;
   double fp_scalar = pow(2, q);
   printf("\nd_%s:", __FUNCTION__);
   for (i = 0; i < n; i++) {
      double a = 0.5 * sin(i * (180.0/(n*0.5)) * M_PI / 180.0);
      double b = 0.5 * cos(i * (180.0/(n*0.5)) * M_PI / 180.0);
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
   lut_Nsincos(1024, 11);
   lut_col2radoffs(80, 13);
   return 0;
}
