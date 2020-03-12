boolean mouseControl = true, showBorder = true, easingOnController = true;
boolean cleanSketch_auto = true, showTarget;
float kinectX, kinectY, easingX, easingY;
float minSize, maxSize, sizeChange;
color bgColor = color(0);

void keyReleased() {
  /*  
   By pressing (and releasing) any of these numbered keys on your keyboard, 
   the function corresponding to that key will be toggled on or off.
   */
   if (key == CODED){
     if (keyCode == UP) {
       println("up");
     }
     if (keyCode == DOWN) {
       println("down");
     }
     if (keyCode == LEFT) {
       println("left");
     }
     if (keyCode == RIGHT) {
       println("right");
     }
   }
   

  if (key == '1') {
    mouseControl = !mouseControl;
    println("Mouse control: " + mouseControl);
  }
  if (key == '2') {
    showBorder = !showBorder;
    println("Show sketch border: " + showBorder);
  }
  if (key == '3') {
    easingOnController = !easingOnController;
    println("Easing on controller: " + easingOnController);
  }
  if (key == '4') {
    cleanSketch_auto = !cleanSketch_auto;
    println("Automatic wipe of sketch: " + cleanSketch_auto);
  }
  if (key == '5') {
    showTarget = !showTarget;
    println("Show target (actual controller position): " + showTarget);
  }
}

void controls() {
  /*
   We can use this function to have the controller follow either our mouse movements (for prototyping),
   or the Kinect, for when we display the sketch on the projector/kinect setup.
   */

  //Track the previous coordinates of controllerX and controllerY
  previousX = controllerX;
  previousY = controllerY;

  if (mouseControl) {
    controllerX = mouseX;
    controllerY = mouseY;
  } else {
    controllerX = kinectX;
    controllerY = kinectY;
  }
}

void showBorder() {
  /*
   We can use this function to draw a rectangle at the perimeter of the sketch, 
   which can help us see the edges of the interactive space, when we project it onto the floor.
   */

  if (showBorder) {
    stroke(255);
    strokeWeight(10);
    noFill();
    rect(0, 0, width, height);
    noStroke();
    fill(255);
  }
}

void easing(float e) {
  /*
   We can use this function for two things:
   1) To average the controller's X/Y coordinates, to avoid jittery motion (especially when controlled by the Kinect).
   In this case use the values for easingX, easingY instead of controllerX, controllerY when drawing the controller.
   2) To display an object that follows the controller, which e.g. can be used as a "cat chasing the mouse" mechanic.
   */

  if (easingOnController) {

    float easing = e;
    float targetX = controllerX;
    float targetY = controllerY;

    float dx = targetX - easingX;
    float dy = targetY - easingY;
    if (abs(dx) > 1) {
      easingX += dx * easing;
    }
    if (abs(dy) > 1) {
      easingY += dy * easing;
    }
    //fill(255, 0, 0);
    //ellipse(easingX, easingY, size/5, size/5);
  }
}

void cleanSketch() {
  //This function momentarily fades a black rectangle on top of the entire sketch, which effectively creates a clean slate for new drawings
  int framesPerSecond = 60;
  if (cleanSketch_auto) {
    if (frameCount%(framesPerSecond*cleanTimerInSeconds) < framesPerSecond/2) {
      fill(bgColor, 20);
      rect(0, 0, width, height);
    }
  }
}

void runFunctions() {
  //Run all the functions described above. This function is called at the bottom of void draw().
  controls();
  showBorder();
  cleanSketch();
  easing(0.05);
}

//Kinect osc handling
void oscEvent(OscMessage theOscMessage) {
  // incoming osc message are forwarded to the oscEvent method.
  // print the address pattern and the typetag of the received OscMessage.
  // print("### received an osc message.");
  // print(" addrpattern: "+theOscMessage.addrPattern());
  // println(" typetag: "+theOscMessage.typetag());

  //kinectX = (int)map(theOscMessage.get(0).intValue(), 0, 640, 640, 0)*2;
  //kinectY = (int)map(theOscMessage.get(1).intValue(), 0, 280, 280, 0)*2+200;

  kinectX = theOscMessage.get(0).intValue()*2+100;
  kinectY = theOscMessage.get(1).intValue()*2;

  //int index = theOscMessage.get(2).intValue();
}

void startKinectOSC() {
  /*
   This function is used to set up the connection with the Kinect Debug Interface, which is made in OpenFrameworks.
   For this Workshop, there is no reason to change any of the give parameters 
   */

  oscP5 = new OscP5(this, 12345);
  myRemoteLocation = new NetAddress("127.0.0.1", 12420);
  println();
  println("Sketch Ready!");
  println();
}
