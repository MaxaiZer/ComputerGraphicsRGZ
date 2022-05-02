#ifndef _NBODY_
#define _NBODY_

#include <stdio.h>
#include <vector_types.h>
#include <cstdlib>
#include <cmath>

#define GL_GLEXT_PROTOTYPES
//#include <GL/glew.h>
#include <GL/glut.h>
#include <cuda_gl_interop.h>

const int ORTHO_VERSION=0; // 1 is 2D version, 0 is 3D version.

#define WINDOW_W 1920
#define WINDOW_H 1080

#define N_SIZE 10000
const int THREADS = 1024;
const int BLOCKS = (N_SIZE + THREADS - 1) / THREADS;
#define SOFT_FACTOR 0.00125f

#define GRAVITATIONAL_CONSTANT 0.01f
#define TIME_STEP 0.001f
#define PI 3.14152926f
#define DENSITY 1000000


extern float4 pos[N_SIZE];
extern float m[N_SIZE];
extern float r[N_SIZE];

struct Camera
{
	float3 pos = { 0, 0, 200 };
	float3 forward = { 0, 0, -1 };
	float3 up = { 0, 1, 0 };

	float theta = 0, phi = PI;// PI;
};

extern Camera camera;

extern GLuint vertexArray;
extern float cx,cy,cz;

 
void init();
void deinit();


void initCUDA();
void initGL();


int runKernelNBodySimulation();

//__global__ 
//void nbody(float4* pos, float4* acc, float4* vel, float* m, float* r);

#endif
