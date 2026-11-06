// Probes for Sunset's two biggest scalar loops: filling memory with a repeated value, and blending 8-bit glyph coverage over RGBA pixels.
#include <arm_neon.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
static double now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec*1e-9;}
#define N(x) __attribute__((noinline)) x
// ---- fill 32-bit pixels
N(void fill_scalar(uint32_t*p,size_t n,uint32_t v)){for(size_t i=0;i<n;i++)p[i]=v;}
N(void fill_neon(uint32_t*p,size_t n,uint32_t v)){uint32x4_t x=vdupq_n_u32(v);size_t i=0;for(;i+16<=n;i+=16){vst1q_u32(p+i,x);vst1q_u32(p+i+4,x);vst1q_u32(p+i+8,x);vst1q_u32(p+i+12,x);}for(;i<n;i++)p[i]=v;}
N(void fill_pattern4(uint32_t*p,size_t n,uint32_t v)){memset_pattern4(p,&v,n*4);}
// ---- fill 64-bit cells
N(void cfill_scalar(uint64_t*p,size_t n,uint64_t v)){for(size_t i=0;i<n;i++)p[i]=v;}
N(void cfill_neon(uint64_t*p,size_t n,uint64_t v)){uint64x2_t x=vdupq_n_u64(v);size_t i=0;for(;i+8<=n;i+=8){vst1q_u64(p+i,x);vst1q_u64(p+i+2,x);vst1q_u64(p+i+4,x);vst1q_u64(p+i+6,x);}for(;i<n;i++)p[i]=v;}
N(void cfill_pattern8(uint64_t*p,size_t n,uint64_t v)){memset_pattern8(p,&v,n*8);}
// ---- blend: dst RGBA bytes, coverage a (0..255), colour c (r,g,b): out = (c*a + d*(255-a) + 127)/255
static inline uint8_t div255(unsigned x){return (uint8_t)((x+128+((x+128)>>8))>>8);} // exact for 0..65025 (x already includes +127? see check)
N(void blend_scalar(uint32_t*d,const uint8_t*a,size_t n,uint8_t r,uint8_t g,uint8_t b)){
  for(size_t i=0;i<n;i++){unsigned al=a[i]; if(!al)continue; unsigned inv=255-al; uint32_t px=d[i];
    unsigned R=(r*al+(px&0xFF)*inv+127)/255,G=(g*al+((px>>8)&0xFF)*inv+127)/255,B=(b*al+((px>>16)&0xFF)*inv+127)/255;
    d[i]=0xFF000000u|(B<<16)|(G<<8)|R;}}
static inline uint8x8_t d255(uint16x8_t x){ // exact (x+127)/255 for x in 0..65025: t=x+127; (t+1+(t>>8))>>8 ... use (t + 1 + (t>>8)) >> 8 == t/255 for t<=65535
  uint16x8_t t=vaddq_u16(x,vdupq_n_u16(127)); uint16x8_t u=vaddq_u16(vaddq_u16(t,vdupq_n_u16(1)),vshrq_n_u16(t,8)); return vshrn_n_u16(u,8);}
N(void blend_neon(uint32_t*d,const uint8_t*a,size_t n,uint8_t r,uint8_t g,uint8_t b)){
  size_t i=0; uint8x8_t cr=vdup_n_u8(r),cg=vdup_n_u8(g),cb=vdup_n_u8(b);
  for(;i+8<=n;i+=8){uint8x8_t al=vld1_u8(a+i); if(vmaxv_u8(al)==0)continue;
    uint8x8x4_t px=vld4_u8((const uint8_t*)(d+i)); uint8x8_t inv=vsub_u8(vdup_n_u8(255),al);
    uint8x8_t R=d255(vaddq_u16(vmull_u8(cr,al),vmull_u8(px.val[0],inv)));
    uint8x8_t G=d255(vaddq_u16(vmull_u8(cg,al),vmull_u8(px.val[1],inv)));
    uint8x8_t B=d255(vaddq_u16(vmull_u8(cb,al),vmull_u8(px.val[2],inv)));
    // coverage 0 keeps destination exactly (inv=255: (d*255+127)/255 = d), so no select needed
    uint8x8x4_t o={{R,G,B,vdup_n_u8(255)}}; vst4_u8((uint8_t*)(d+i),o);}
  for(;i<n;i++){unsigned al=a[i]; if(!al)continue; unsigned inv=255-al; uint32_t px=d[i];
    unsigned R=(r*al+(px&0xFF)*inv+127)/255,G=(g*al+((px>>8)&0xFF)*inv+127)/255,B=(b*al+((px>>16)&0xFF)*inv+127)/255;
    d[i]=0xFF000000u|(B<<16)|(G<<8)|R;}}
#define REP 20000
int main(void){
  size_t W=2040, H=34; size_t n=W*H; // one terminal row strip at 2x (120 cols x 17 px)
  uint32_t*buf=aligned_alloc(64,n*4),*ref=aligned_alloc(64,n*4);
  double best[3]={1e9,1e9,1e9}; void(*f[3])(uint32_t*,size_t,uint32_t)={fill_scalar,fill_neon,fill_pattern4};
  const char*nm[3]={"scalar loop","NEON 64B/iter","memset_pattern4"};
  for(int k=0;k<3;k++){for(int rep=0;rep<7;rep++){double t=now();for(int i=0;i<2000;i++)f[k](buf,n,0xFF112233u+i);t=(now()-t)/2000;if(t<best[k])best[k]=t;}
    printf("pixel strip fill 2040x34 (277 KB): %-16s %7.2f us  %6.1f GB/s\n",nm[k],best[k]*1e6,n*4/best[k]/1e9);}
  size_t cn=120; uint64_t cb_[120],cr_[120]; double cbst[3]={1e9,1e9,1e9}; void(*g[3])(uint64_t*,size_t,uint64_t)={cfill_scalar,cfill_neon,cfill_pattern8};
  const char*cn_[3]={"scalar loop","NEON","memset_pattern8"};
  for(int k=0;k<3;k++){for(int rep=0;rep<7;rep++){double t=now();for(int i=0;i<200000;i++){g[k](cb_,cn,0x1234+i);__asm__ volatile(""::"r"(cb_):"memory");}t=(now()-t)/200000;if(t<cbst[k])cbst[k]=t;}
    printf("cell row blank 120x8 B (960 B):   %-16s %7.1f ns\n",cn_[k],cbst[k]*1e9);}
  // blend: a glyph-shaped coverage (about 40%% non-zero, mixed), 17x34 per cell -> run over a whole row's worth: 120 cells x 14 x 24 px of coverage
  size_t px=120*14*24; uint8_t*cov=malloc(px); srand(1); for(size_t i=0;i<px;i++){int v=rand()%100; cov[i]=v<60?0:(v<75?255:(uint8_t)(rand()%256));}
  uint32_t*d1=aligned_alloc(64,px*4),*d2=aligned_alloc(64,px*4); for(size_t i=0;i<px;i++)d1[i]=d2[i]=0xFF000000u|(uint32_t)rand();
  blend_scalar(d1,cov,px,200,100,50); blend_neon(d2,cov,px,200,100,50); size_t bad=0; for(size_t i=0;i<px;i++)if(d1[i]!=d2[i])bad++;
  printf("blend differential: %zu of %zu pixels differ\n",bad,px);
  double bs=1e9,bn=1e9; for(int rep=0;rep<7;rep++){double t=now();for(int i=0;i<2000;i++)blend_scalar(d1,cov,px,200,100,50);t=(now()-t)/2000;if(t<bs)bs=t;t=now();for(int i=0;i<2000;i++)blend_neon(d2,cov,px,200,100,50);t=(now()-t)/2000;if(t<bn)bn=t;}
  printf("glyph blend, %zu coverage bytes (a row of text): scalar %7.2f us (%.2f ns/px)  NEON %7.2f us (%.2f ns/px)  %.1fx\n",px,bs*1e6,bs*1e9/px,bn*1e6,bn*1e9/px,bs/bn);
  return 0;}
