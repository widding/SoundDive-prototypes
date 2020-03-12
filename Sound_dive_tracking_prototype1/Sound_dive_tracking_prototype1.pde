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

int minDepth =  60;
int maxDepth = 1008;

color trackColor; 
float threshold = 25;
float distThreshold = 6;

ArrayList<Blob> blobs = new ArrayList<Blob>();

void setup() {
  size(640, 360);
  
  kinect = new Kinect(this);
  kinect.initVideo();
  kinect.initDepth();
  // Blank image
  depthImg = new PImage(kinect.width, kinect.height);
  trackingImg = new PImage(kinect.width, kinect.height);
  //String[] cameras = Capture.list();
  //printArray(cameras);
  //video = new Capture(this, 640, 360);
  //video.start();
  trackColor = color(255);
}

/*
void captureEvent(Capture video) {
  video.read();
}
*/

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


  println(distThreshold);
}

void draw() {
  //video.loadPixels();
  image(kinect.getVideoImage(), 0, 0);

  blobs.clear();

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
  image(trackingImg, 0, 0);
  
  
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
  
  println(blobs.size());
  
  if (blobs.size() == 2){
  PVector red = new PVector();
  PVector green = new PVector();
  
  for (Blob b : blobs) {
      println(b.size());
      if (b.size()<15){
        b.show(color(0,255,0));
        println(b.minx, b.maxx, b.getCenter().x, b.miny, b.maxy, b.getCenter().y);
        green = new PVector(b.getCenter().x, b.getCenter().y); 
      }
      else {
        b.show(color(255,0,0));
        println(b.minx, b.maxx, b.getCenter().x, b.miny, b.maxy, b.getCenter().y);
        red = new PVector(b.getCenter().x, b.getCenter().y);
      }
    
  }
  /*
  pushMatrix();
  translate(red.x, red.y);
  popMatrix();
  */
  
  }

  textAlign(RIGHT);
  fill(255);
  text("distance threshold: " + distThreshold, width-10, 25);
  text("color threshold: " + threshold, width-10, 50);
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
  int loc = mouseX + mouseY*kinect.getVideoImage().width;
  trackColor = kinect.getVideoImage().pixels[loc];
}
