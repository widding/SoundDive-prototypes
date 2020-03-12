// Daniel Shiffman
// http://codingtra.in
// http://patreon.com/codingtrain
// Code for: https://youtu.be/1scFcY-xMrI
/*
import processing.video.*;

Capture video;
*/
import org.openkinect.freenect.*;
import org.openkinect.processing.*;

Kinect kinect;

PImage depthImg;
PImage trackingImg;

boolean debugInfo = false;
boolean videoMode = false;

int minDepth =  60;
int maxDepth = 1032;

color trackColor; 
float threshold = 25;
float distThreshold = 6;

float trackBrightness = 250;
int minBlobSize = 8;
ArrayList<Blob> blobs = new ArrayList<Blob>();

ArrayList<PVector> ignoreList = new ArrayList<PVector>();
int ignoreDist = 150;

void setup() {
  size(640, 360);
  
  kinect = new Kinect(this);
  kinect.initVideo();
  kinect.initDepth();
  // Blank image
  depthImg = new PImage(kinect.width, kinect.height);
  trackingImg = new PImage(kinect.width, kinect.height);
  trackColor = color(255);
}


void keyPressed() {
  if (key == 'a') {
    distThreshold+=5;
  } else if (key == 'z') {
    distThreshold-=5;
  }
  if (key == 's') {
    threshold+=5;
  } else if (key == 'x') {
    threshold-=5;
  }
  
  if (key == 'd') {
    minDepth+=5;
  } else if (key == 'c') {
    minDepth-=5;
  }
  
  if (key == 'f') {
    maxDepth+=1;
  } else if (key == 'v') {
    maxDepth-=1;
  }


  println(distThreshold);
}

void draw() {
  /*
  println();
  println("size before clear", blobs.size());
  for (int i = 0; i < blobs.size(); i++) {
    println("after", blobs.get(i).size());
  }
  */
  
  blobs.clear();

    // Threshold the depth image
  int[] rawDepth = kinect.getRawDepth();
  for (int i=0; i < rawDepth.length; i++) {
    float red = red(kinect.getVideoImage().pixels[i]);
    float green = green(kinect.getVideoImage().pixels[i]);
    float blue = red(kinect.getVideoImage().pixels[i]);
    float bright = (red+green+blue)/3;
    
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth && bright > trackBrightness) {
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
  if (!videoMode) image(trackingImg, 0, 0);
  else image(kinect.getVideoImage(), 0, 0);
  
  
  // Begin loop to walk through every pixel
  for (int x = 0; x < trackingImg.width; x++ ) {
    for (int y = 0; y < trackingImg.height; y++ ) {
     
      
      int loc = x + y * trackingImg.width;
      // What is current color
      color currentColor = trackingImg.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(trackColor);
      float g2 = green(trackColor);
      float b2 = blue(trackColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      //if (currentColor==trackColor) {
      if (d < threshold*threshold) {
        //println(currentColor, trackColor);

        boolean found = false;
        for (Blob b : blobs) {
          if (b.isNear(x, y)) {
            b.add(x, y);
            found = true;
            break;
          }
        }

        if (!found) {
          Blob b = new Blob(x, y);
          blobs.add(b);
          
        }
      }
      
    }
  }
  
  //println("size before remove", blobs.size());
  //println("start");
  for (int i = 0; i < blobs.size(); i++) {
    //println("before", blobs.get(i).size());
    if (blobs.get(i).size() < 5) {
      //blobs.remove(i);
    }
  }
  
  
  
  //println("stop");
  
  //
  /*
  for (int i = 0; i < ignoreList.size(); i++){
    //println("chack 1", blobs.size(), j);
    for (int j = 0; j < blobs.size(); j++){
    
      //println("chack 2", ignoreList.size(), i);
      //println(dist(ignoreList.get(i).x, ignoreList.get(i).y, blobs.get(j).getCenter().x, blobs.get(j).getCenter().y));
      if (dist(ignoreList.get(i).x, ignoreList.get(i).y, blobs.get(j).getCenter().x, blobs.get(j).getCenter().y) < ignoreDist) {
        //println("Found blob within threshold");
        //println("Blob size ", blobs.size(), " blob index ", j);
        //println("Ignorelist size", ignoreList.size(), " size index ", i);
        //println("removing blob at ", blobs.get(j).getCenter().x, blobs.get(j).getCenter().y); 
        blobs.remove(j);
        //j--;
        //println("chack 3");
         
      }
    }
  }
  */

  
  //println("2:", blobs.size());
  
  if (blobs.size() == 2 && blobs.get(0).size() > minBlobSize && blobs.get(1).size() > minBlobSize){
  
  
  //if (!videoMode) image(trackingImg, 0, 0);
  //else image(kinect.getVideoImage(), 0, 0);
    
  PVector red = new PVector();
  PVector redOffset = new PVector();
  PVector green = new PVector();
  PVector greenOffset = new PVector();
  boolean redIsFound = false;
  boolean greenIsFound = false;
  
  println();
  for (Blob b : blobs) {
      
      //if (b.size()>5){
      //println("b size", b.size(), b.getCenter().x, b.getCenter().y);
      if (b.size()<50){
        greenIsFound = true;
        b.show(color(0,255,0));
        //println(b.minx, b.maxx, b.getCenter().x, b.miny, b.maxy, b.getCenter().y);
        green = new PVector(b.getCenter().x, b.getCenter().y); 
      }
      else {
        redIsFound = true;
        b.show(color(255,0,0));
        //println(b.minx, b.maxx, b.getCenter().x, b.miny, b.maxy, b.getCenter().y);
        red = new PVector(b.getCenter().x, b.getCenter().y);
      }
     // }
  }
  
  if (redIsFound && greenIsFound){
  redOffset = new PVector(0, -150);
  greenOffset = new PVector((green.x - red.x), (green.y - red.y - 150));
  
  float a = PVector.angleBetween(redOffset, greenOffset);
  if (greenOffset.x < redOffset.x){
    println(180 + 180-degrees(a));
  }
  else println(degrees(a));  // Prints "10.304827"
  }

  
  }
  
  if (debugInfo){
  textAlign(RIGHT);
  fill(255);
  text("distance threshold: " + distThreshold, width-10, 25);
  text("color threshold: " + threshold, width-10, 50);
  text("min depth: " + minDepth, width-10, 75);
  text("max depth: " + maxDepth, width-10, 100);
  
  for (int i = 0; i < ignoreList.size(); i++){
    noFill();
    stroke(255, 0, 0);
    ellipse(ignoreList.get(i).x, ignoreList.get(i).y, ignoreDist/2, ignoreDist/2);
  }
  }
}


// Custom distance functions w/ no square root for optimization
float distSq(float x1, float y1, float x2, float y2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
  return d;
}


float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

void mousePressed() {
  // Save color where the mouse is clicked in trackColor variable
  ignoreList.add(new PVector(mouseX, mouseY));
}

void keyReleased(){
  if (key=='i') debugInfo = !debugInfo;
  if (key=='v') videoMode = !videoMode;
}
