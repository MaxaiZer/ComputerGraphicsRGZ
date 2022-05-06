#include <stdio.h>
#include <vector_types.h>
#include <cstdlib>
#include <cmath>

#define GL_GLEXT_PROTOTYPES
#include <GL/glut.h>
#include <cuda_gl_interop.h>

#define WINDOW_W 1920
#define WINDOW_H 1080
#define PI 3.14152926f

extern int BODIES;
extern float4* pos;
extern float* m;
extern float* r;

struct Camera
{
	float4 pos = { 0, 0, 200 };
	float4 forward = { 0, 0, -1 };
	float4 up = { 0, 1, 0 };

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
