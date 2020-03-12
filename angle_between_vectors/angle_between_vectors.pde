void setup(){
  size(300,300);
  translate(width/2, height/2);
}

void draw(){
  translate(width/2, height/2);
  ellipse(0,0,10,10);
  PVector v1 = new PVector(0, -150);
  //println(mouseX-150, mouseY-150);
  PVector v2 = new PVector(mouseX-150, mouseY-150); 
  float a = PVector.angleBetween(v1, v2);
  if (v2.x < v1.x){
    println(180 + 180-degrees(a));
  }
  else println(degrees(a));  // Prints "10.304827"
}
