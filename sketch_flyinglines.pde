import themidibus.*;
MidiBus myBus;

NodeSystem ns; // the System
int num = 600; // number of nodes
ArrayList <Node> nodes; // a list of nodes
float maxDistance = 0.0;
float minDistance = 0.0;
float targetMaxDistance = 0.0;
float targetMinDistance = 0.0;
float rampRate = 1.3;

// Background settings
int faderate = 10;
int backR = 0;
int backB = 0;
int backG = 0;

// camera steering and viewing
float zoom = 0.0;
float horizontalAngle = 0.0;
float verticalAngle = PI/4;
float spinCamera = 0.0;
float targetSpinCamera = 0.8;

// speed
float zoomSpeedCamera = 400;  
float rotationSpeedCamera = 0.2; // radiants per second
float rotationSpeedObject = 2.0;


// text draw
boolean lookoutDraw = false;

//Mouse Draw
boolean mDraw = false;
int mDrawA = 0;
int mDrawB = 0;

//------------------CAMERA FUNCTIONS------------------------
void changeHorizontalAngle (float deltaAnglePerSecond)  // 0° .. 360°
{
  horizontalAngle += deltaAnglePerSecond / frameRate;
  if (horizontalAngle > 2*PI) horizontalAngle -= 2*PI;
  if (horizontalAngle < 0) horizontalAngle += 2*PI;
}

void changeVerticalAngle (float deltaAnglePerSecond)  // -90° .. +90°°
{
  verticalAngle = constrain(verticalAngle + deltaAnglePerSecond / frameRate, -PI/2, +PI/2);
}

void changeZoom (float deltaValuePerSecond)
{
  zoom = constrain (zoom + deltaValuePerSecond / frameRate, -300, 222);
}
//--------------------------------------------------------

void setup(){
  
  size(1024,768, OPENGL);
  background(0);
  smooth();
  
  //Set up MIDI connection
  MidiBus.list();
  myBus = new MidiBus(this, "ProcessingPort", -1);
  //create the NodeSystem
  ns = new NodeSystem();   
  //initalise nodes
  ns.init(num);

}// end of setup

void draw(){
  noFill();
  noStroke();
  fill( backR, backG, backB, faderate);
  box(width*2, height*2, height*2); 
  if (spinCamera != 0) changeHorizontalAngle (spinCamera * rotationSpeedCamera);
  pushMatrix();
    translate(width/2, height/2, zoom);
    rotateX(-verticalAngle);
    rotateY(horizontalAngle);
    
    //drawings
    
    ns.run();
    
    if (lookoutDraw){
      textSize(32);
      fill(255, 255, 255);
      text("l o o k o u t", -80, 30); 
    }
    
    if(mDraw){  
      PVector  v1 = nodes.get(mDrawA).pos; 
      PVector  v2 = nodes.get(mDrawB).pos; 
      stroke(255, 170, 200);    
      strokeWeight(4);
      line(v1.x , v1.y, v1.z, v2.x, v2.y, v2.z); // draw the line
      strokeWeight(1);
    }
    
    
  popMatrix();

}

//---------MIDI Functions-------------
void noteOn(int channel, int pitch, int velocity) { // NoteOn function only runs when a Note On message is recieved
  //Receive a noteOn and trigger events
  
  /*
  println();  // uncomment to see all the incoming messages
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
  */
  
  randomSeed( hour() + second() + millis() );
  
  if((channel==0)&&(pitch==63)){ // speed pulse
    faderate = velocity;
  }
  
  if((channel==0)&&(pitch==64)){ // speed pulse
    spinCamera = 13.0;
  }
  
  if((channel==0)&&(pitch==65)){ // distance pulse
    maxDistance = 140.0;
    minDistance = 100.0;
  }
  
  if((channel==0)&&(pitch==67)){ // Draw pink line
    mDraw = true;
    selectRandomNodes();
  }
  
  if((channel==0)&&(pitch==68)){ // Change VerticalAngle
    verticalAngle = (velocity-100);
  }
  
  if((channel==0)&&(pitch==70)){
    //change background color to random color
    backR = int(random(255));
    backB = int(random(255));
    backG = int(random(255));
  }
  
  if((channel==0)&&(pitch==71)){ //set b
    backB = int(velocity * 1.77);
  }
  
  if((channel==0)&&(pitch==72)){ //set g
    backG = int(velocity * 2.77);
  }
  
  if((channel==0)&&(pitch==73)){ //set r
    backR = int(velocity * 2.77);
  }
  
  if((channel==0)&&(pitch==75)){ //set distance
    targetMaxDistance = int(velocity);
  }
  
  if((channel==0)&&(pitch==77)){ //set lookout draw
    if(velocity > 20){
      lookoutDraw = true;
    }
    else{
      lookoutDraw = false;
    }
  }

  
}

void noteOff(int channel, int pitch, int velocity) { // NoteOff function only runs when a Note Off message is recieved
  // trigger any events on note off
  if((channel==0)&&(pitch==67)){ // Draw pink line
    mDraw = false;
  }
}

void selectRandomNodes(){
    mDrawA = int(random(nodes.size()));
    mDrawB = int(random(nodes.size()));
    while(mDrawA == mDrawB){ //make sure not same node
      mDrawB = int(random(nodes.size()));
    }
}

void mousePressed(){
    //change background colour
    backR = int(random(255));
    backB = int(random(255));
    backG = int(random(255));
    //on mouse press draw pink line between two random nodes
    mDraw = true;
    mDrawA = int(random(nodes.size()));
    mDrawB = int(random(nodes.size()));
    while(mDrawA == mDrawB){ //make sure not same node
      mDrawB = int(random(nodes.size()));
    }

}

void mouseReleased(){
  mDraw = false;
}


class Node{
  PVector pos; // the node position
  PVector vel; // the velocity of the node
  float diam; // the diameter
  int cons = 0; // the connection he has
  
  // the constructor
  Node(PVector pos,float diam){
    this.pos = pos;
    this.diam = diam;
    // start with own velocity
    vel = new PVector(random(-0.6,0.6),random(1.6,2.2),random(-0.6,0.6));
  }

  // draw the node
  void show(){ 
    fill(255);
    translate(pos.x, pos.y, pos.z);
    sphere(diam);
  }
  
  // update the posiotn
  void update() {
    // Motion 101: Locations changes by velocity.
    pos.add(vel);
  }
  
  // check Edges makes them come in from the other side
  void checkEdges() {

    if (pos.x > 500) {
      pos.x = -500;
    } else if (pos.x < -500) {
      pos.x = 500;
    }
    
    if (pos.y > 500) {
      pos.y = -500;
    } else if (pos.y < -500) {
      pos.y = 500;
    }
    
    if (pos.z > 500) {
      pos.z = -500;
    } else if (pos.z < -500) {
      pos.z = 500;
    }

  }// end checkEdges
}

class NodeSystem{

  // constructor 
  NodeSystem(){
  }


  // this initalizes the nodes
  void init(int num){
    
    nodes = new ArrayList();
    
    // loop thru num
    for(int i = 0; i < num; i++){
      // make a random point 
      float x = random(10, width - 10);
      float y = random(10, height - 10);
      float z = random(10, 800 - 10);
      
      float diam = 1;// with diameter
      
      PVector pos = new PVector(x,y,z);// position into PVector
      Node n = new Node(pos,diam); 
      nodes.add(n); // add the new node to the list
    }
  
  }
  
  
  // run the nodesystem
  void run(){
    
    spinCamera = rampVal(spinCamera, targetSpinCamera);
    maxDistance = rampVal(maxDistance, targetMaxDistance);
    minDistance = rampVal(minDistance, targetMinDistance);
    display();
    
  }
  
  // calculate the connections and draw the lines
  void calcConnections(Node n){
    
    int num = 0; // number of connections
  
    for(int i = 0; i < nodes.size(); i ++){
      
        PVector  v1 = n.pos; // position of the refrence positoin
        PVector  v2 = nodes.get(i).pos; // every other node
        float d =  PVector.dist(v1, v2);// calc the distance
    
    
        if((d < maxDistance + n.cons* 3) && (d > minDistance)){
         
          stroke(255);     
          line(v1.x , v1.y, v1.z, v2.x, v2.y, v2.z); // draw the line
                  num++; // increment num
        }
      // set the connections of the node to the num
    n.cons = num;
    }
  }
  
  // display the nodes and draw the connections
  void display(){
  
    Node n = null;// keep it clear
         
    for(int i = 0; i < nodes.size(); i++){
      n = nodes.get(i);
      // call the functions of node
      n.checkEdges(); 
      calcConnections(n);
      n.diam = n.cons/3; // set the size
      //n.show();// display
      n.update(); // and update position
      
     }
      
  } // end display

}

float rampVal(float curVal,float targetVal){
  if (curVal < targetVal){
    return curVal+rampRate;
  } else {
    return curVal-rampRate;
  }
}