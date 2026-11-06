#include <arm_neon.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
static double now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec*1e-9;}
static inline uint32_t bp(uint32_t d,uint32_t a,uint32_t r,uint32_t g,uint32_t b){uint32_t i=255-a;return 0xFF000000u|(((b*a+((d>>16)&255)*i+127)/255)<<16)|(((g*a+((d>>8)&255)*i+127)/255)<<8)|((r*a+(d&255)*i+127)/255);}
static void scal(uint32_t*d,const uint8_t*c,size_t n,uint32_t col){uint32_t r=col&255,g=(col>>8)&255,b=(col>>16)&255;for(size_t i=0;i<n;i++)if(c[i])d[i]=bp(d[i],c[i],r,g,b);}
static inline uint8x8_t d255(uint16x8_t x){uint16x8_t t=vaddq_u16(x,vdupq_n_u16(127));return vshrn_n_u16(vaddq_u16(vaddq_u16(t,vdupq_n_u16(1)),vshrq_n_u16(t,8)),8);}
static inline void b8(uint32_t*d,uint8x8_t a,uint8x8_t cr,uint8x8_t cg,uint8x8_t cb){uint8x8x4_t p=vld4_u8((const uint8_t*)d);uint8x8_t inv=vsub_u8(vdup_n_u8(255),a);uint8x8x4_t o;o.val[0]=d255(vaddq_u16(vmull_u8(cr,a),vmull_u8(p.val[0],inv)));o.val[1]=d255(vaddq_u16(vmull_u8(cg,a),vmull_u8(p.val[1],inv)));o.val[2]=d255(vaddq_u16(vmull_u8(cb,a),vmull_u8(p.val[2],inv)));o.val[3]=vdup_n_u8(255);vst4_u8((uint8_t*)d,o);}
__attribute__((noinline)) static void k_scalar_tail(uint32_t*d,const uint8_t*c,size_t n,uint32_t col){uint8x8_t cr=vdup_n_u8(col&255),cg=vdup_n_u8((col>>8)&255),cb=vdup_n_u8((col>>16)&255);size_t i=0;for(;i+8<=n;i+=8){uint8x8_t a=vld1_u8(c+i);if(vmaxv_u8(a)==0)continue;b8(d+i,a,cr,cg,cb);}scal(d+i,c+i,n-i,col);}
__attribute__((noinline)) static void k_pad_tail(uint32_t*d,const uint8_t*c,size_t n,uint32_t col){uint8x8_t cr=vdup_n_u8(col&255),cg=vdup_n_u8((col>>8)&255),cb=vdup_n_u8((col>>16)&255);size_t i=0;for(;i+8<=n;i+=8){uint8x8_t a=vld1_u8(c+i);if(vmaxv_u8(a)==0)continue;b8(d+i,a,cr,cg,cb);}
 size_t rest=n-i;if(rest){uint8_t pc[8]={0};uint32_t pd[8]={0xFF000000u,0xFF000000u,0xFF000000u,0xFF000000u,0xFF000000u,0xFF000000u,0xFF000000u,0xFF000000u};for(size_t k=0;k<rest;k++){pc[k]=c[i+k];pd[k]=d[i+k];}uint8x8_t a=vld1_u8(pc);if(vmaxv_u8(a)){b8(pd,a,cr,cg,cb);for(size_t k=0;k<rest;k++)d[i+k]=pd[k];}}}
// tail by overlapping-safe approach: process the last 8 with a mask of the pixels not yet done (coverage zeroed for the first 8-rest lanes)
__attribute__((noinline)) static void k_overlap_tail(uint32_t*d,const uint8_t*c,size_t n,uint32_t col){uint8x8_t cr=vdup_n_u8(col&255),cg=vdup_n_u8((col>>8)&255),cb=vdup_n_u8((col>>16)&255);size_t i=0;for(;i+8<=n;i+=8){uint8x8_t a=vld1_u8(c+i);if(vmaxv_u8(a)==0)continue;b8(d+i,a,cr,cg,cb);}
 size_t rest=n-i;if(rest&&n>=8){uint8x8_t a=vld1_u8(c+n-8);static const uint8_t idx[8]={0,1,2,3,4,5,6,7};uint8x8_t lane=vld1_u8(idx);uint8x8_t keep=vcge_u8(lane,vdup_n_u8((uint8_t)(8-rest)));a=vand_u8(a,keep);if(vmaxv_u8(a))b8(d+n-8,a,cr,cg,cb);}else if(rest){scal(d+i,c+i,rest,col);}}
int main(void){size_t W=13,H=29,cells=2880;size_t n=W*H;uint8_t*cov=malloc(n);uint32_t*dst=malloc(n*4),*d1=malloc(n*4),*d2=malloc(n*4),*d3=malloc(n*4);srand(3);for(size_t i=0;i<n;i++){int v=rand()%100;cov[i]=v<60?0:(v<75?255:rand()%256);dst[i]=0xFF000000u|(rand()&0xFFFFFF);}
 for(size_t i=0;i<n;i++)d1[i]=d2[i]=d3[i]=dst[i];for(size_t r=0;r<H;r++){k_scalar_tail(d1+r*W,cov+r*W,W,0xFF3070C0);k_pad_tail(d2+r*W,cov+r*W,W,0xFF3070C0);k_overlap_tail(d3+r*W,cov+r*W,W,0xFF3070C0);}
 size_t bad2=0,bad3=0;for(size_t i=0;i<n;i++){bad2+=d1[i]!=d2[i];bad3+=d1[i]!=d3[i];}printf("differential: pad %zu, overlap %zu\n",bad2,bad3);
 double best[3]={1e9,1e9,1e9};
 for(int rep=0;rep<15;rep++){for(int k=0;k<3;k++){double t=now();for(int g=0;g<300;g++)for(size_t r=0;r<H;r++){uint32_t*d=dst+r*W;if(k==0)k_scalar_tail(d,cov+r*W,W,0xFF3070C0);else if(k==1)k_pad_tail(d,cov+r*W,W,0xFF3070C0);else k_overlap_tail(d,cov+r*W,W,0xFF3070C0);}t=(now()-t)/300;if(t<best[k])best[k]=t;}}
 const char*nm[3]={"NEON + scalar tail","NEON + padded tail","NEON + overlapped masked tail"};for(int k=0;k<3;k++)printf("%-30s %7.2f ns per 13x29 glyph  (%.1f us per 2880-glyph frame)\n",nm[k],best[k]*1e9,best[k]*cells*1e6);return 0;}
