#include "nbody.cuh"
#include <iostream>
#include <fstream>
#include <device_launch_parameters.h>

int bodies_size_float3 = 0;
int bodies_size_float = 0;
float3 *pos_dev = NULL;
float3 *vel_dev = NULL;
float3 *acc_dev = NULL;
float *m_dev = NULL;
float *r_dev = NULL;

float3 pos[N_SIZE];
float3 vel[N_SIZE];
float3 acc[N_SIZE];
float m[N_SIZE];
float r[N_SIZE];

Camera camera;

GLuint vertexArray;

__device__
int icbrt2(unsigned x) {
   int s;
   unsigned y, b, y2;

   y2 = 0;
   y = 0;
   for (s = 30; s >= 0; s = s - 3) {
      y2 = 4*y2;
      y = 2*y;
      b = (3*(y2 + y) + 1) << s;
      if (x >= b) {
         x = x - b;
         y2 = y2 + 2*y + 1;
         y = y + 1;
      }
   }
   return y;
}

void initBody(int i)
{
	pos[i].x = (-WINDOW_W / 2 + ((float)rand() / (float)(RAND_MAX)) * WINDOW_W) * 0.9;
	pos[i].y = (-WINDOW_H / 2 + ((float)rand() / (float)(RAND_MAX)) * WINDOW_H) * 0.9;
	pos[i].z = (-500 + ((float)rand() / (float)(RAND_MAX)) * 500) * 0.9;

	acc[i].x = -50 + ((float)rand() / (float)(RAND_MAX)) * 50;
	acc[i].y = -50 + ((float)rand() / (float)(RAND_MAX)) * 50;
	acc[i].z = -50 + ((float)rand() / (float)(RAND_MAX)) * 50;

	vel[i].x = -50 + ((float)rand() / (float)(RAND_MAX)) * 50;
	vel[i].y = -50 + ((float)rand() / (float)(RAND_MAX)) * 50;
	vel[i].z = -50 + ((float)rand() / (float)(RAND_MAX)) * 50;

	r[i] = ((float)rand() / (float)(RAND_MAX)) * 3.0;
	m[i] = 4.0 / 3.0 * PI * pow(r[i],3) * DENSITY;
}

void initCUDA()
{


	bodies_size_float3 = N_SIZE * sizeof(float3);
	bodies_size_float = N_SIZE * sizeof(float);

	cudaMalloc( (void**)&pos_dev, bodies_size_float3 ); 
	cudaMalloc( (void**)&acc_dev, bodies_size_float3 ); 
	cudaMalloc( (void**)&vel_dev, bodies_size_float3 ); 
	cudaMalloc( (void**)&m_dev, bodies_size_float ); 
	cudaMalloc( (void**)&r_dev, bodies_size_float ); 

	for(int i = 0; i < N_SIZE; i++){
		initBody(i);
	}


	cudaMemcpy( pos_dev, pos, bodies_size_float3, cudaMemcpyHostToDevice );
	cudaMemcpy( acc_dev, acc, bodies_size_float3, cudaMemcpyHostToDevice );
	cudaMemcpy( vel_dev, vel, bodies_size_float3, cudaMemcpyHostToDevice );
	cudaMemcpy( m_dev, m, bodies_size_float, cudaMemcpyHostToDevice );
	cudaMemcpy( r_dev, r, bodies_size_float, cudaMemcpyHostToDevice );

}

void initGL()
{
    glEnable(GL_CULL_FACE);
	glEnable(GL_POINT_SIZE);

    glEnable(GL_LIGHTING);
    glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE);

    glEnable(GL_LIGHT0);
    glEnable(GL_COLOR_MATERIAL);

	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    /*void glOrtho(GLdouble  left,  GLdouble  right,  GLdouble  bottom,  GLdouble  top,  GLdouble  nearVal,  GLdouble  farVal);*/

    gluPerspective (45, (float)WINDOW_W/(float)WINDOW_H, 1, 2000);
   
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

   	gluLookAt(camera.pos.x,camera.pos.y,camera.pos.z, //Camera position
    camera.pos.x+camera.forward.x,camera.pos.y+camera.forward.y,camera.pos.z+camera.forward.z, //Position of the object to look at
    camera.up.x,camera.up.y,camera.up.z); //Camera up direction


	glEnable(GL_DEPTH_TEST);
	glEnable(GL_FOG);
}

// init the program
void init()
{
	initGL();
	initCUDA();
	atexit(deinit);
}

void deinit()
{
	cudaFree( pos_dev );
	cudaFree( r_dev );
	cudaFree( m_dev );
	cudaFree( acc_dev );
	cudaFree( vel_dev )	;
}

__device__
void updatePosAndVel(float3 pos[], float3 vel[], float3 acc[], float3 cur_a, int self)
{
	float newvx = vel[self].x + (acc[self].x + cur_a.x ) / 2 * TIME_STEP;
	float newvy = vel[self].y + (acc[self].y + cur_a.y ) / 2 * TIME_STEP;
	float newvz = vel[self].z + (acc[self].z + cur_a.z ) / 2 * TIME_STEP;

	//update position
	pos[self].x += newvx * TIME_STEP + acc[self].x * TIME_STEP * TIME_STEP /2;
	pos[self].y += newvy * TIME_STEP + acc[self].y * TIME_STEP * TIME_STEP /2;
	pos[self].z += newvz * TIME_STEP + acc[self].z * TIME_STEP * TIME_STEP /2;

	//update velocity
	vel[self].x = newvx;
	vel[self].y = newvy;
	vel[self].z = newvz; 
}

__device__
void bodyBodyInteraction(float3 &acc, float m[], int self, int other, float3 dist3, float dist_sqr)
{
	float dist_six = dist_sqr * dist_sqr * dist_sqr;
	float dist_cub = sqrtf(dist_six);

	// this is according to the Newton's law of universal gravitaion
	acc.x += (m[other] * dist3.x) / dist_cub;
	acc.y += (m[other] * dist3.y) / dist_cub;
	acc.z += (m[other] * dist3.z) / dist_cub;
}

template <class T>
__device__ void swap(T& first, T& second)
{
	T tmp = first;
	first = second;
	second = tmp;
}

__device__
void mergeBodies(float m[], float3 vel[], float3 acc[], int self, int other)
{
	float newMass = m[self] + m[other];

	// Used perfectly unelastic collision model to caculate the velocity after merging.
	float3 velocity;

	velocity.x = (vel[self].x * m[self] + vel[other].x * m[other]) / newMass;
	velocity.y = (vel[self].y * m[self] + vel[other].y * m[other]) / newMass;
	velocity.z = (vel[self].z * m[self] + vel[other].z * m[other]) / newMass;

	float3 zero_float3 = { 0.0f, 0.0f, 0.0f } ;
	acc[self] = zero_float3;
	acc[other] = zero_float3;

	int biggerIndex = self, smallerIndex = other;

	if (m[biggerIndex] < m[smallerIndex])
	{
		swap(biggerIndex, smallerIndex);
	}

	m[biggerIndex] = newMass;
	vel[biggerIndex] = velocity;
	m[smallerIndex] = 0.0f;
	vel[smallerIndex] = zero_float3;	
}

__global__ 
void nbody(float3* pos, float3* acc, float3* vel, float* m, float* r) 
{
	int idx = blockIdx.x * THREADS + threadIdx.x;

	if (idx >= N_SIZE || m[idx] == 0)
		return;

	float oldMass = m[idx];

	// initiate the acceleration of the next moment 
	float3 cur_acc = { 0.0f, 0.0f, 0.0f };

	// for any two body
	for (int i = 0; i < N_SIZE; i++) {

		if (i != idx && m[i] != 0) {

			if (m[idx] == 0)
				continue;

			float3 dist3; // calculate their distance

			dist3.x = pos[i].x - pos[idx].x;
			dist3.y = pos[i].y - pos[idx].y;
			dist3.z = pos[i].z - pos[idx].z;

			// update the force between two non-empty bodies
			float dist_sqr = dist3.x * dist3.x + dist3.y * dist3.y + dist3.z * dist3.z + SOFT_FACTOR;

			if (sqrt(dist_sqr) > r[idx] + r[i])
				bodyBodyInteraction(cur_acc, m, idx, i, dist3, dist_sqr);
			else
				mergeBodies(m, vel, acc, idx, i);

		}
	}

	// multiplies a Gravitational Constant
	cur_acc.x *= GRAVITATIONAL_CONSTANT;
	cur_acc.y *= GRAVITATIONAL_CONSTANT;
	cur_acc.z *= GRAVITATIONAL_CONSTANT;

	//update the position and velocity
	updatePosAndVel(pos, vel, acc, cur_acc, idx);

	// update the body acceleration
	acc[idx].x = cur_acc.x;
	acc[idx].y = cur_acc.y;
	acc[idx].z = cur_acc.z;

	// if the mass is changed, update the radius
	if (m[idx] != oldMass)
		r[idx] = icbrt2(m[idx] / (DENSITY * 4.0 / 3.0 * PI));
}

int runKernelNBodySimulation()
{
	// Map the buffer to CUDA

	nbody<<<BLOCKS, THREADS>>>(pos_dev, acc_dev, vel_dev, m_dev, r_dev);

	cudaMemcpy( pos, pos_dev, bodies_size_float3, cudaMemcpyDeviceToHost ); 
	cudaMemcpy( m, m_dev, bodies_size_float, cudaMemcpyDeviceToHost ); 
	cudaMemcpy( r, r_dev, bodies_size_float, cudaMemcpyDeviceToHost ); 

	return EXIT_SUCCESS;
}
