// Daniel Shiffman
// Depth thresholding example

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

// Original example by Elie Zananiri
// http://www.silentlycrashing.net

import org.openkinect.freenect.*;
import org.openkinect.processing.*;

Kinect kinect;

// Depth image
PImage depthImg;
PImage trackingImg;

// Which pixels do we care about?
int minDepth =  60;
int maxDepth = 1008;

// What is the kinect's angle
float angle;

void setup() {
  size(1280, 480);

  kinect = new Kinect(this);
  kinect.initDepth();
  kinect.initVideo();
  
  angle = kinect.getTilt();

  // Blank image
  depthImg = new PImage(kinect.width, kinect.height);
  trackingImg = new PImage(kinect.width, kinect.height);
}

void draw() {
  println(red(get(mouseX,mouseY)), green(get(mouseX,mouseY)), blue(get(mouseX,mouseY)), brightness(get(mouseX,mouseY)));
  // Draw the raw image
  image(kinect.getDepthImage(), 0, 0);

  // Threshold the depth image
  int[] rawDepth = kinect.getRawDepth();
  for (int i=0; i < rawDepth.length; i++) {
    float red = red(kinect.getVideoImage().pixels[i]);
    float green = green(kinect.getVideoImage().pixels[i]);
    float blue = red(kinect.getVideoImage().pixels[i]);
    float bright = (red+green+blue)/3;
    
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth && bright > 250) {
      depthImg.pixels[i] = color(255);
      trackingImg.pixels[i] = kinect.getVideoImage().pixels[i];
    } 
    else {
      depthImg.pixels[i] = color(0);
      trackingImg.pixels[i] = color(0);
    }
  }

  // Draw the thresholded image
  depthImg.updatePixels();
  trackingImg.updatePixels();
  //image(depthImg, kinect.width, 0);
  image(trackingImg, kinect.width, 0);

  fill(0);
  text("TILT: " + angle, 10, 20);
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, 36);
}

// Adjust the angle and the depth threshold min and max
void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      angle++;
    } else if (keyCode == DOWN) {
      angle--;
    }
    angle = constrain(angle, 0, 30);
    kinect.setTilt(angle);
  } else if (key == 'a') {
    minDepth = constrain(minDepth+10, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth-10, 0, maxDepth);
  } else if (key == 'z') {
    maxDepth = constrain(maxDepth+10, minDepth, 2047);
  } else if (key =='x') {
    maxDepth = constrain(maxDepth-10, minDepth, 2047);
  }
}
