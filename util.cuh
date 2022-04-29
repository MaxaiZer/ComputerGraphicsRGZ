#ifndef _UTIL_
#define _UTIL_

//void timerFunc(int value);

// defined the key board function
void keyboardFunc(unsigned char key, int x, int y);

// defined call back function triggered by mouse
void mouseCallback(int x, int y);

// defined callback function for resizing the view
void resizeCallback(int w, int h);

// for the last mouse motion
void PassiveMouseMotion(int x, int y);

void draw2(void);

void cross(float x1, float y1, float z1, float x2, float y2, float z2,float& rightX, float& rightY, float& rightZ);


#endif