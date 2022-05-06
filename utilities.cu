#include "utilities.cuh"
#include "nbody.cuh"
#include <ctime>
#include <string>

#define ESC_CODE 27

float prevX = WINDOW_W / 2, prevY = WINDOW_H / 2;
bool toggleHelp = true;
bool mouseUp = 0;

extern float4* pos;
extern float4* vel;
extern float4* acc;
extern float* m;
extern float* r;

GLfloat lpos[4] = {-0.3,0.0,200,0}; //позиция света
GLfloat light_specular[4] = {1, 0.6, 1, 0}; //интенсивность зеркального света
GLfloat light_diffuse[] = { 1.0, 1.0, 1.0, 0.0 }; //интенсивность рассеянного света 
GLfloat light_ambient[] = { 0.2, 0.2, 0.2, 0.0 };  //интенсивность окружающего света
GLfloat a;
GLfloat mat_emission[] = {0.8, 0.5, 0.3, 0.0}; // свойство материала (излучение света)
GLfloat mat_specular[] = { 4.0, 0.5, 2.0, 0.0 };  //зеркальность материала объекта
GLfloat low_shininess[] = { 50 };
GLfloat fogColor[] = {0.5f, 0.5f, 0.5f, 1};

float fps;
float lastFrameTime = 0;
int frameNumber = 0;

const int FOV = 40;

void resizeCallback(int w, int h)
{
    if (h == 0)
        h = 1;

    float ratio = 1.0 * w / h;

    //сброс системы координат
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    //установка обалсти окна
    glViewport(0, 0, w, h);

    //установка перспективы
    gluPerspective(45, ratio, 1, 1000);
    glMatrixMode(GL_MODELVIEW);
}

void handleKeyboard(unsigned char key, int x, int y)
{
    if (key == ESC_CODE)
        exit(0);

    float vel = 5.0;
    float rightX, rightY, rightZ;
    cross(camera.forward.x, camera.forward.y, camera.forward.z, camera.up.x, camera.up.y, camera.up.z, rightX, rightY, rightZ);
    float sizeRight = sqrtf(rightX * rightX + rightY * rightY + rightZ * rightZ);
    rightX /= sizeRight; rightY /= sizeRight; rightZ /= sizeRight;

    int coef1 = 0;
    int coef2 = 0;

    switch (key)
    {
    case 'w':
        coef1 = 1; // вперёд
        break;
    case 's':
        coef1 = -1; // назад
        break;
    case 'a':
        coef2 = -1; // влево
        break;
    case 'd':
        coef2 = 1; // вправо
        break;
    }

    if (coef1 != 0)
    {
        camera.pos.x += camera.forward.x * vel * coef1;
        camera.pos.y += camera.forward.y * vel * coef1;
        camera.pos.z += camera.forward.z * vel * coef1;
    }

    if (coef2 != 0)
    {
        camera.pos.x += rightX * vel * coef2;
        camera.pos.y += rightY * vel * coef2;
        camera.pos.z += rightZ * vel * coef2;
    }

    if (key == 'h') // show or hide help
    {
        toggleHelp = !toggleHelp;
    }
}

void saveMousePos(int x, int y)
{
    prevX = x, prevY = y;
}

void handleMouse(int x, int y)
{
    float velx = (float(x - prevX) / WINDOW_W);
    float vely = (float(y - prevY) / WINDOW_H);
    prevX = x;
    prevY = y;
    camera.phi += -velx * PI * 0.9;
    camera.theta += -vely * PI * 0.9;

    float rightX, rightY, rightZ;
    rightX = sinf(camera.phi - PI / 2.0f);
    rightY = 0;
    rightZ = cosf(camera.phi - PI / 2.0f);
    float sizeRight = sqrtf(rightX * rightX + rightY * rightY + rightZ * rightZ);
    rightX /= sizeRight; rightY /= sizeRight; rightZ /= sizeRight;


    float cosTheta = cosf(camera.theta);
    camera.forward.x = cosTheta * sinf(camera.phi);
    camera.forward.y = sinf(camera.theta);
    camera.forward.z = cosTheta * cosf(camera.phi);

    float sizeForward = sqrtf(camera.forward.x * camera.forward.x + camera.forward.y * camera.forward.y + camera.forward.z * camera.forward.z);
    camera.forward.x /= sizeForward; camera.forward.y /= sizeForward; camera.forward.z /= sizeForward;

    float newUpX, newUpY, newUpZ;

    cross(rightX, rightY, rightZ, camera.forward.x, camera.forward.y, camera.forward.z, newUpX, newUpY, newUpZ);
    float sizeUp = sqrtf(newUpX * newUpX + newUpY * newUpY + newUpZ * newUpZ);
    camera.up.x = newUpX / sizeUp; camera.up.y = newUpY / sizeUp; camera.up.z = newUpZ / sizeUp;
}

float getVectorsAngle(float4 v1, float4 v2)
{
    float cos = (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z) /
        ( sqrtf(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z) * 
            sqrtf(v2.x * v2.x + v2.y * v2.y + v2.z * v2.z) );
    return acos(cos) * 180.0 / PI;
}

void cross(float x1, float y1, float z1, float x2, float y2, float z2,float& rightX, float& rightY, float& rightZ)
{
    rightX = y1*z2 - z1*y2;
    rightY = x1*z2 - x1*z2;
    rightZ = x1*y2 - y1*x1;
}

void setLights()
{
    glMaterialfv(GL_FRONT, GL_EMISSION, mat_emission);
    glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT, GL_SHININESS, low_shininess);
    glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
    glLightfv(GL_LIGHT0, GL_POSITION, lpos);

    //Туман
    glFogfv(GL_FOG_COLOR, fogColor);
    glFogi(GL_FOG_MODE, GL_LINEAR);
    glFogf(GL_FOG_START, 10.0f);
    glFogf(GL_FOG_END, 1000.0f);
}

void calculateFPS()
{
    float currentTime = clock();// / 1000.0;
    fps = (float)1000 / (currentTime - lastFrameTime);
    lastFrameTime = currentTime;
    frameNumber++;
}

void drawScene()
{
    calculateFPS();

    glClearColor(0.1f,0.1f,0.1f,0.1f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(camera.pos.x,camera.pos.y,camera.pos.z, //Camera position
              camera.pos.x+camera.forward.x,camera.pos.y+camera.forward.y,camera.pos.z+camera.forward.z, //Position of the object to look at
              camera.up.x,camera.up.y,camera.up.z); //Camera up direction
    setLights();

	runKernelNBodySimulation();

    if (frameNumber % 40 == 0)
    {
        printf("FPS: %.3f\n", fps);
    }

    glColor3f(0.5f, 0.5f, 0.3f);
    
    for(int i = 0; i < BODIES; i ++)
    {
        if (m[i] == 0)
            continue;

        float4 bodyVector = { pos[i].x - camera.pos.x, pos[i].y - camera.pos.y, pos[i].z - camera.pos.z };
        if (getVectorsAngle(camera.forward, bodyVector) > FOV)
            continue;

		glPushMatrix();
		glTranslatef(pos[i].x, pos[i].y, pos[i].z);
		glutSolidSphere(r[i], 10, 10); // draw sphere
		glPopMatrix();          
    }

    glutSwapBuffers();

}