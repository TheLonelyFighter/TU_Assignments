// Marius-Mihail Gurgu, Alexandre Thomas Janin, Wei-Heng Ke

#include <immintrin.h>
#include <emmintrin.h>
#include <malloc.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <math.h>

#define IDCT_SIZE         16
#define ITERATIONS        1000000
#define MAX_NEG_CROP      1024

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))
#define MAX(X,Y) ((X) > (Y) ? (X) : (Y))

static const short g_aiT16[16][16] =   //why not use char instead
{
  { 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64},
  { 90, 87, 80, 70, 57, 43, 25,  9, -9,-25,-43,-57,-70,-80,-87,-90},
  { 89, 75, 50, 18,-18,-50,-75,-89,-89,-75,-50,-18, 18, 50, 75, 89},
  { 87, 57,  9,-43,-80,-90,-70,-25, 25, 70, 90, 80, 43, -9,-57,-87},
  { 83, 36,-36,-83,-83,-36, 36, 83, 83, 36,-36,-83,-83,-36, 36, 83},
  { 80,  9,-70,-87,-25, 57, 90, 43,-43,-90,-57, 25, 87, 70, -9,-80},
  { 75,-18,-89,-50, 50, 89, 18,-75,-75, 18, 89, 50,-50,-89,-18, 75},
  { 70,-43,-87,  9, 90, 25,-80,-57, 57, 80,-25,-90, -9, 87, 43,-70},
  { 64,-64,-64, 64, 64,-64,-64, 64, 64,-64,-64, 64, 64,-64,-64, 64},
  { 57,-80,-25, 90, -9,-87, 43, 70,-70,-43, 87,  9,-90, 25, 80,-57},
  { 50,-89, 18, 75,-75,-18, 89,-50,-50, 89,-18,-75, 75, 18,-89, 50},
  { 43,-90, 57, 25,-87, 70,  9,-80, 80, -9,-70, 87,-25,-57, 90,-43},
  { 36,-83, 83,-36,-36, 83,-83, 36, 36,-83, 83,-36,-36, 83,-83, 36},
  { 25,-70, 90,-80, 43,  9,-57, 87,-87, 57, -9,-43, 80,-90, 70,-25},
  { 18,-50, 75,-89, 89,-75, 50,-18,-18, 50,-75, 89,-89, 75,-50, 18},
  {  9,-25, 43,-57, 70,-80, 87,-90, 90,-87, 80,-70, 57,-43, 25, -9}
};

static int64_t diff(struct timespec start, struct timespec end)
{
    struct timespec temp;
    int64_t d;
    if ((end.tv_nsec-start.tv_nsec)<0) {
        temp.tv_sec = end.tv_sec-start.tv_sec-1;
        temp.tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
    } else {
        temp.tv_sec = end.tv_sec-start.tv_sec;
        temp.tv_nsec = end.tv_nsec-start.tv_nsec;
    }
    d = temp.tv_sec*1000000000+temp.tv_nsec;
    return d;
}

static void compare_results(short *ref, short *res, const char *msg)
{
    int correct =1;

    printf("Comparing %s\n",msg);
    for(int j=0; j<IDCT_SIZE; j++)  {
        for(int i=0; i<IDCT_SIZE; i++){
            if(ref[j*IDCT_SIZE+i] != res[j*IDCT_SIZE+i]){
                correct=0;
                printf("failed at %d,%d\t ref=%d, res=%d\n ", i, j, ref[j*IDCT_SIZE+i],res[j*IDCT_SIZE+i]);
            }
        }
    }
    if (correct){
        printf("The answer is correct bby\n\n");
    }
}

// this function is for timing, do not change anything here
static void benchmark( void (*idct16)(short *, short *), short *input, short *output, const char *version )
{
    struct timespec start, end;
    clock_gettime(CLOCK_REALTIME,&start);

    for(int i=0;i<ITERATIONS;i++)
        idct16(input, output);

    clock_gettime(CLOCK_REALTIME,&end);
    double avg = (double) diff(start,end)/ITERATIONS;
    printf("%10s:\t %.3f ns\n", version, avg);
}

//scalar code for the inverse transform
static void partialButterflyInverse16(short *src, short *dst, int shift)
{
  int E[8],O[8];
  int EE[4],EO[4];
  int EEE[2],EEO[2];
  int add = 1<<(shift-1); // calculates 2 to the power of (shift - 1)

  for (int j=0; j<16; j++)
  {
    /* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
    for (int k=0; k<8; k++)
    {
      O[k] = g_aiT16[ 1][k]*src[ 16] + g_aiT16[ 3][k]*src[ 3*16] + g_aiT16[ 5][k]*src[ 5*16] + g_aiT16[ 7][k]*src[ 7*16] +
        g_aiT16[ 9][k]*src[ 9*16] + g_aiT16[11][k]*src[11*16] + g_aiT16[13][k]*src[13*16] + g_aiT16[15][k]*src[15*16];
    }
    for (int k=0; k<4; k++)
    {
      EO[k] = g_aiT16[ 2][k]*src[ 2*16] + g_aiT16[ 6][k]*src[ 6*16] + g_aiT16[10][k]*src[10*16] + g_aiT16[14][k]*src[14*16];
    }
    EEO[0] = g_aiT16[4][0]*src[ 4*16 ] + g_aiT16[12][0]*src[ 12*16 ];
    EEE[0] = g_aiT16[0][0]*src[ 0    ] + g_aiT16[ 8][0]*src[  8*16 ];
    EEO[1] = g_aiT16[4][1]*src[ 4*16 ] + g_aiT16[12][1]*src[ 12*16 ];
    EEE[1] = g_aiT16[0][1]*src[ 0    ] + g_aiT16[ 8][1]*src[  8*16 ];

    /* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
    for (int k=0; k<2; k++)
    {
      EE[k] = EEE[k] + EEO[k];
      EE[k+2] = EEE[1-k] - EEO[1-k];
    }
    for (int k=0; k<4; k++)
    {
      E[k] = EE[k] + EO[k];
      E[k+4] = EE[3-k] - EO[3-k];
    }
    for (int k=0; k<8; k++)
    {
      dst[k]   = MAX( -32768, MIN( 32767, (E[k]   + O[k]   + add)>>shift ));
      dst[k+8] = MAX( -32768, MIN( 32767, (E[7-k] - O[7-k] + add)>>shift ));
    }
    src ++;  // why increment only by 1?
    dst += 16; //why increment by 16?
  }
}

void print128_16(__m128i var) // function used to print 8 integers packed in 128 variable
{
    int16_t val[8];
    memcpy(val, &var, sizeof(val));
    printf("__m128i: %i %i %i %i %i %i %i %i \n", 
           val[0], val[1], val[2], val[3], val[4], val[5], 
           val[6], val[7]);
}

void print128_32(__m128i var) // function used to print 4 integers packed in 128 variable
{
    int32_t val[4];
    memcpy(val, &var, sizeof(val));
    printf("__m128i: %i %i %i %i \n", 
           val[0], val[1], val[2], val[3]);
}

static void partialButterflyInverse16_simd(short *src, short *dst, int shift)
{
  int E[8],O[8];
  int EE[4],EO[4], E0_debug[4];
  int EEE[2],EEO[2];
  int add = 1<<(shift-1); // calculates 2 to the power of (shift - 1)

  for (int j=0; j<16; j++)
  {
    /* Utilizing symmetry properties to the maximum to minimize the number of multiplications */
    for (int k=0; k<8; k++)
    {
      __m128i xmm0, xmm1, xmm2, xmm3;

      xmm0 = _mm_set_epi32(g_aiT16[ 7][k], g_aiT16[ 5][k],g_aiT16[ 3][k],g_aiT16[ 1][k]);
      xmm1 = _mm_set_epi32(src[ 7*16],src[ 5*16],src[ 3*16],src[16]);
      xmm2 = _mm_set_epi32(g_aiT16[ 15][k], g_aiT16[ 13][k],g_aiT16[ 11][k],g_aiT16[ 9][k]);
      xmm3 = _mm_set_epi32(src[ 15*16],src[ 13*16],src[ 11*16],src[9*16]);

      xmm0 = _mm_mullo_epi32(xmm0, xmm1);
      xmm2 = _mm_mullo_epi32(xmm2, xmm3);

      xmm0 = _mm_add_epi32(xmm0,xmm2);

      xmm0 =  _mm_hadd_epi32(xmm0,xmm0);
      xmm0 =  _mm_hadd_epi32(xmm0,xmm0);
      
      O[k] = _mm_extract_epi32(xmm0, 0);
    }

    __m128i xmm0 = _mm_set_epi32(g_aiT16[ 2][3],g_aiT16[ 2][2],g_aiT16[ 2][1],g_aiT16[ 2][0]); // ((__m128i *) (g_aiT16[2]))[0];
    __m128i xmm1 = _mm_set_epi32(g_aiT16[ 6][3],g_aiT16[ 6][2],g_aiT16[ 6][1],g_aiT16[ 6][0]);
    __m128i xmm2 = _mm_set_epi32(g_aiT16[10][3],g_aiT16[10][2],g_aiT16[10][1],g_aiT16[10][0]);
    __m128i xmm3 = _mm_set_epi32(g_aiT16[14][3],g_aiT16[14][2],g_aiT16[14][1],g_aiT16[14][0]);
    
    xmm0 = _mm_mullo_epi32(xmm0, _mm_set1_epi32(src[2*16]));
    xmm1 = _mm_mullo_epi32(xmm1, _mm_set1_epi32(src[6*16]));
    xmm2 = _mm_mullo_epi32(xmm2, _mm_set1_epi32(src[10*16]));
    xmm3 = _mm_mullo_epi32(xmm3, _mm_set1_epi32(src[14*16]));
    
    xmm0 = _mm_add_epi32(xmm0,xmm1);
    xmm0 = _mm_add_epi32(xmm0,xmm2);
    xmm0 = _mm_add_epi32(xmm0,xmm3);

    EO[0] = _mm_extract_epi32(xmm0, 0);
    EO[1] = _mm_extract_epi32(xmm0, 1);
    EO[2] = _mm_extract_epi32(xmm0, 2);
    EO[3] = _mm_extract_epi32(xmm0, 3);	  

	  
    EEO[0] = g_aiT16[4][0]*src[ 4*16 ] + g_aiT16[12][0]*src[ 12*16 ];
    EEE[0] = g_aiT16[0][0]*src[ 0    ] + g_aiT16[ 8][0]*src[  8*16 ];
    EEO[1] = g_aiT16[4][1]*src[ 4*16 ] + g_aiT16[12][1]*src[ 12*16 ];
    EEE[1] = g_aiT16[0][1]*src[ 0    ] + g_aiT16[ 8][1]*src[  8*16 ];

    /* Combining even and odd terms at each hierarchy levels to calculate the final spatial domain vector */
    
    EE[0] = EEE[0] + EEO[0];
    EE[1] = EEE[1] + EEO[1];
    EE[2] = EEE[1] - EEO[1];
    EE[3] = EEE[0] - EEO[0];

    // SIMD version is actually slower
    // xmm0 = _mm_set_epi32(EEE[0],EEE[1],EEE[1],EEE[0]);
    // xmm1 = _mm_set_epi32(-EEO[0],-EEO[1],EEO[1],EEO[0]);
    // xmm0 = _mm_add_epi32(xmm0,xmm1);
    // _mm_store_si128((__m128i*) EE, xmm0);
  
    E[0] = EE[0] + EO[0];
    E[1] = EE[1] + EO[1];
    E[2] = EE[2] + EO[2];
    E[3] = EE[3] + EO[3];
    E[4] = EE[3] - EO[3];
    E[5] = EE[2] - EO[2];
    E[6] = EE[1] - EO[1];
    E[7] = EE[0] - EO[0];

    __m128i a = _mm_set1_epi32(add);
    __m128i min = _mm_set1_epi32(32767);
    __m128i max = _mm_set1_epi32(-32768);
    __m128i e0 = _mm_load_si128((__m128i*) E);
    __m128i e4 = _mm_load_si128((__m128i*) &E[4]);
    __m128i o0 = _mm_load_si128((__m128i*) O);
    __m128i o4 = _mm_load_si128((__m128i*) &O[4]);
    
    __m128i d0 = _mm_add_epi32(e0, o0);
    d0 = _mm_add_epi32(d0, a);
    d0 = _mm_srai_epi32(d0, shift);
    d0 = _mm_min_epi32(d0, min);
    d0 = _mm_max_epi32(d0, max);
    dst[0] = _mm_extract_epi32(d0, 0);
    dst[1] = _mm_extract_epi32(d0, 1);
    dst[2] = _mm_extract_epi32(d0, 2);
    dst[3] = _mm_extract_epi32(d0, 3);
    
    __m128i d4 = _mm_add_epi32(e4, o4);
    d4 = _mm_add_epi32(d4, a);
    d4 = _mm_srai_epi32(d4, shift);
    d4 = _mm_min_epi32(d4, min);
    d4 = _mm_max_epi32(d4, max);
    dst[4] = _mm_extract_epi32(d4, 0);
    dst[5] = _mm_extract_epi32(d4, 1);
    dst[6] = _mm_extract_epi32(d4, 2);
    dst[7] = _mm_extract_epi32(d4, 3);
    
    __m128i d8 = _mm_sub_epi32(e4, o4);
    d8 = _mm_add_epi32(d8, a);
    d8 = _mm_srai_epi32(d8, shift);
    d8 = _mm_min_epi32(d8, min);
    d8 = _mm_max_epi32(d8, max);
    dst[8] = _mm_extract_epi32(d8, 3);
    dst[9] = _mm_extract_epi32(d8, 2);
    dst[10] = _mm_extract_epi32(d8, 1);
    dst[11] = _mm_extract_epi32(d8, 0);
    
    __m128i d12 = _mm_sub_epi32(e0, o0);
    d12 = _mm_add_epi32(d12, a);
    d12 = _mm_srai_epi32(d12, shift);
    d12 = _mm_min_epi32(d12, min);
    d12 = _mm_max_epi32(d12, max);
    dst[12] = _mm_extract_epi32(d12, 3);
    dst[13] = _mm_extract_epi32(d12, 2);
    dst[14] = _mm_extract_epi32(d12, 1);
    dst[15] = _mm_extract_epi32(d12, 0);

    src ++;  // why increment only by 1?
    dst += 16; //why increment by 16?
  }
}

static void idct16_scalar(short* pCoeff, short* pDst)
{
  short tmp[ 16*16] __attribute__((aligned(16)));
  partialButterflyInverse16(pCoeff, tmp, 7);
  partialButterflyInverse16(tmp, pDst, 12);
}

/// CURRENTLY SAME CODE AS SCALAR !!
/// REPLACE HERE WITH SSE intrinsics
static void idct16_simd(short* pCoeff, short* pDst)
{
  short tmp[ 16*16] __attribute__((aligned(16)));
  partialButterflyInverse16_simd(pCoeff, tmp, 7);
  partialButterflyInverse16_simd(tmp, pDst, 12);
}

int main(int argc, char **argv)
{
    //allocate memory 16-byte aligned
    short *scalar_input = (short*) memalign(16, IDCT_SIZE*IDCT_SIZE*sizeof(short));
    short *scalar_output = (short *) memalign(16, IDCT_SIZE*IDCT_SIZE*sizeof(short));

    short *simd_input = (short*) memalign(16, IDCT_SIZE*IDCT_SIZE*sizeof(short));
    short *simd_output = (short *) memalign(16, IDCT_SIZE*IDCT_SIZE*sizeof(short));

    //initialize input
    printf("input array:\n");
    for(int j=0;j<IDCT_SIZE;j++){
        for(int i=0;i<IDCT_SIZE;i++){
            short value = rand()%2 ? (rand()%32768) : -(rand()%32768) ;  //50 % neg coeffs and 50% pos coeffs
            scalar_input[j*IDCT_SIZE+i] = value;
            simd_input  [j*IDCT_SIZE+i] = value;
	    printf("%d\t", value);
        }
        printf("\n");
    }

    idct16_scalar(scalar_input, scalar_output);
    idct16_simd  (simd_input  , simd_output); //call with random short signed numbers

    //check for correctness
    compare_results (scalar_output, simd_output, "scalar and simd");

    printf("output array:\n");
    for(int j=0;j<IDCT_SIZE;j++){
        for(int i=0;i<IDCT_SIZE;i++){
	    printf("%d\t", scalar_output[j*IDCT_SIZE+i]);
        }
        printf("\n");
    }

    //Measure the performance of each kernel
    benchmark (idct16_scalar, scalar_input, scalar_output, "scalar");
    benchmark (idct16_simd, simd_input, simd_output, "simd");

    //cleanup
    free(scalar_input);    free(scalar_output);
    free(simd_input); free(simd_output);
}
