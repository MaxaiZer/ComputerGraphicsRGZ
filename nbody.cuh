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
const int THREADS = 256;
const int BLOCKS = (N_SIZE + THREADS - 1) / THREADS;
#define SOFT_FACTOR 0.00125f

#define GRAVITATIONAL_CONSTANT 0.01f
#define TIME_STEP 0.001f
#define PI 3.14152926f
#define DENSITY 1000000


extern float3 pos[N_SIZE];
extern float m[N_SIZE];
extern float r[N_SIZE];

struct Camera {
    float camX, camY, camZ;
    float forwardX, forwardY, forwardZ; 
    float upX, upY, upZ; 

    float theta, phi;

    Camera() {
        camX = 0, camY = 0, camZ = 200;
        forwardX = 0, forwardY = 0, forwardZ = -1;
        upX = 0, upY = 1, upZ = 0;

        theta = 0; phi = PI;
    }
};

extern Camera camera;
extern GLuint vertexArray;
extern float cx,cy,cz;

 
void init();
void deinit();


void initCUDA();
void initGL();


int runKernelNBodySimulation();

__global__ 
void nbody(float3* pos, float3* acc, float3* vel, float* m, float* r);

#endif
