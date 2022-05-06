#include "utilities.cuh"
#include "nbody.cuh"
#include <iostream>
#include <fstream>

int main(int argc, char **argv) 
{
    srand(time(NULL));

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGBA|GLUT_DOUBLE| GLUT_DEPTH);
    glutInitWindowPosition(50, 25);

    glutInitWindowSize(WINDOW_W,WINDOW_H);
    glutCreateWindow("NBody Simulation");

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable( GL_BLEND );

    glutDisplayFunc(drawScene);
    glutIdleFunc(drawScene);

    glutKeyboardFunc(handleKeyboard);
    glutMotionFunc(handleMouse);
    glutPassiveMotionFunc(saveMousePos);
    glutReshapeFunc(resizeCallback);

    init();
    glutMainLoop();

    return 0;
}
