import gab.opencv.*;
import org.openkinect.freenect.*;
import org.openkinect.processing.*;

Kinect kinect;

OpenCV opencv;

PImage src;

void setup() {
  
  //src.resize(800, 0);
  size(640, 480);
  kinect = new Kinect(this);
  kinect.initVideo();
  //src = kinect.getVideoImage();
  opencv = new OpenCV(this, 640, 480);  
}

void draw() {
  
  opencv.loadImage(kinect.getVideoImage());
  src = opencv.getSnapshot();
  
  image(opencv.getOutput(), 0, 0); 
  PVector loc = opencv.max();
  
  stroke(255, 0, 0);
  strokeWeight(4);
  noFill();
  ellipse(loc.x, loc.y, 10, 10);
}
