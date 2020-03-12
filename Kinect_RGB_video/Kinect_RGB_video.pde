// Daniel Shiffman
// All features test

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

import org.openkinect.freenect.*;
import org.openkinect.processing.*;

Kinect kinect;

void setup() {
  size(640, 480);
  kinect = new Kinect(this);
  kinect.initVideo();
}


void draw() {
  image(kinect.getVideoImage(), 0, 0);
}
