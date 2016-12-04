/**
 * Vector Dot Lines (v3.5)
 * by GokPotter (2013/Feb)
 * modders v.k., Thomas.Diewald, GoToLoop
 *
 * works faster when compiled in P1.5.1!
 *
 * http://forum.processing.org/topic/gradual-movement-within-a-for-loop
 * http://forum.processing.org/topic/drawing-a-network-of-nodes-and-links
 */

import java.util.Arrays;
import java.util.*;

final static color BG = -1, FG = 5;
final static short DOT_DIST  =50, DOT_OPAC = 60;
final static float DOT_SPEED = 0, FPS = 60, BOLD = 1;

static int NUM_DOTS  = 4000;

final static String GFX = P2D;  

int A = 64; //average degree
int R;
int T = 0; // 0, 1, or two for square disk, or sphere respectively


int avg_degree;
float coverage = 0;
PVector uniformCirclePosition = new PVector(0,0);

String status = "Square";
String inputStatus = "START";
boolean statusChanged = false;
boolean showEdges = true;
boolean sortAdjacency = false;
boolean discovered = false;
boolean displayCoverage = true;
String input = "";
int backbone = 0;
float maxDist = 0;

Point maxPoint;
Point minPoint;
ArrayList<Point> points;
ArrayList<Point> sorted;
ArrayList<Integer> topColors = new ArrayList<Integer>();
HashMap<Integer, Integer> colorDistribution = new HashMap<Integer, Integer>();
PrintWriter output;
PrintWriter verticeOutput;
PrintWriter colorDistOutput;
PrintWriter vertexDegrees;

color[] colorList = new color[30];

void setup() {
  size(800, 800, GFX);
  frameRate(FPS);
  smooth();
  strokeWeight(BOLD);
  stroke(5, 200, 200, DOT_OPAC);
  fill(5,100, 100);
  ellipseMode(CENTER);
  rectMode(CENTER);
  
  uniformCirclePosition = new PVector(width * 0.5, height / 2);
  createColors();
  
  setupNodes();
  

}

void createColors() {
  colorList[0] = color(0);
  colorList[1] = color(51,255,0);
  colorList[2] = color(102,255,0);
  colorList[3] = color(153,255,0);
  colorList[4] = color(204,255,0);
  colorList[5] = color(255,255,0);
  colorList[6] = color(255,204,0);
  colorList[7] = color(255,153,0);
  colorList[8] = color(255,102,0);
  colorList[9] = color(255,51,0);
  colorList[10] = color(255,0,0);
  colorList[11] = color(255,0,51);
  colorList[12] = color(255,0,102);
  colorList[13] = color(255,0,153);
  colorList[14] = color(255,0,204);
  colorList[15] = color(255,0,255);
  colorList[16] = color(204,0,255);
  colorList[17] = color(153,0,255);
  colorList[18] = color(102,0,255);
  colorList[19] = color(51,0,255);
  colorList[20] = color(0,0,255);
  colorList[21] = color(0,51,255);
  colorList[22] = color(0,102,255);
  colorList[23] = color(0,153,255);
  colorList[24] = color(0,204,255);
  colorList[25] = color(0,255,255);
  colorList[26] = color(0,255,204);
  colorList[27] = color(0,255,153);
  colorList[28] = color(0,255,102);
  colorList[29] = color(0,255,51);
}

void keyPressed(){
  if (key == ENTER) {
     sortAdjacency = true;
     discovered = true;
  } else if (keyCode == LEFT) {
    if (backbone == 0) {
      backbone = 6;
    } else {
      backbone--;
    }
    println("BackBone: " + backbone);
    displayCoverage = true;
  } else if (keyCode == RIGHT) {
    if (backbone == 6) {
      backbone = 0;
    } else {
      backbone++;
    }
    println("BackBone: " + backbone);
    displayCoverage = true;
  }
  
}

void setupNodes() {
    noFill();
    stroke(255, 0, 0);
    
    if (status == "Square") {
        maxDist = solveForR();
        print("Max Distance: " + solveForR());
        //rect(0, 0, height, height);
    } else if (status == "Disk") {
        maxDist = solveForRDisk();
        print("Max Distance: " + solveForRDisk());
        ellipse(uniformCirclePosition.x, uniformCirclePosition.y, height, height);
    }
    stroke(FG, DOT_OPAC);
    fill(.5,.5,.8);
    
    avg_degree = 0;
    if (status == "Square") {
       points = prepareSquareNodes(); 
    } else {
       points = prepareDiskNodes();  
    }
    
}

void createAdjacencyList() {
  Collections.sort(points, new CompareTo());
  // save adjlist to file
  output = createWriter("adjlist.txt");  // created output file
  output.println("AdjacencyList");
  output.println();
  for (int i = 0; i < points.size(); i++) {
    output.print("["+points.get(i).name+"]->");
    for (int j = 0; j < points.get(i).adjacentPoints.size(); j++) {
      output.print("["+points.get(i).adjacentPoints.get(j)+"]");
    }
    output.println();
  }
  
  output.flush();
  output.close();
  print("saved");
}

void draw() {
    background(BG);
    drawOutline();
  
    //avg_degree = 0;
     Collections.sort(points, new CompareTo());
    
    coverage = 0;
    ArrayList<Integer> coveredNodes = new ArrayList<Integer>();
    
    for (int i = 0; i < NUM_DOTS; i++) {
      Point p = (Point)points.get(i);
      
      if (backbone == 0) {
        p.drawPoint();
        nearestNeighbors(p, i, maxDist, points);
      } else if (backbone == 1 && discovered) {
        if (p.vertexColor == topColors.get(0) || p.vertexColor == topColors.get(1)) {
          p.drawPoint();
          connectBackbone(p, i, maxDist, points, 0, 1, coveredNodes);
        }
      } else if (backbone == 2 && discovered) {
        if (p.vertexColor == topColors.get(0) || p.vertexColor == topColors.get(2)) {
          p.drawPoint();
          connectBackbone(p, i, maxDist, points, 0, 2, coveredNodes);
        }
      } else if (backbone == 3 && discovered) {
        if (p.vertexColor == topColors.get(0) || p.vertexColor == topColors.get(3)) {
          p.drawPoint();
          connectBackbone(p, i, maxDist, points, 0, 3, coveredNodes);
        }
      } else if (backbone == 4 && discovered) {
        if (p.vertexColor == topColors.get(1) || p.vertexColor == topColors.get(2)) {
          p.drawPoint();
          connectBackbone(p, i, maxDist, points, 1, 2, coveredNodes);
        }
      } else if (backbone == 5 && discovered) {
        if (p.vertexColor == topColors.get(1) || p.vertexColor == topColors.get(3)) {
          p.drawPoint();
          connectBackbone(p, i, maxDist, points, 1, 3, coveredNodes);
        }
      } else if (backbone == 6 && discovered) {
        if (p.vertexColor == topColors.get(2) || p.vertexColor == topColors.get(3)) {
          p.drawPoint();
          connectBackbone(p, i, maxDist, points, 2, 3, coveredNodes);
        }
      }
    }
    
    float coverage = (float)(coveredNodes.size() / (float)NUM_DOTS);
    if (displayCoverage) {
      if (backbone == 1)
        DFS(0,1);
      else if (backbone == 2)
        DFS(0,2);
      else if (backbone == 3)
        DFS(0,3);
      else if (backbone == 4)
        DFS(1,2);
      else if (backbone == 5)
        DFS(1,3);
      else if (backbone == 6)
        DFS(2,3);
      
      println("Coverage: " + coverage);
      displayCoverage = false;
    }
    
    if (sortAdjacency) {
      long startTime = System.nanoTime();
      createAdjacencyList();
      long endTime = System.nanoTime();
      System.out.println("Build adjacencylist time: " + (endTime - startTime) + " ns");
      
      startTime = System.nanoTime();
      getVerticeDegrees(points);
      endTime = System.nanoTime();
      System.out.println("find verticy degrees time: " + (endTime - startTime) + " ns");
      
      startTime = System.nanoTime();
      sorted = sortAdjacencyListByDegree(points);
      endTime = System.nanoTime();
      System.out.println("sortByDegree: " + (endTime - startTime) + " ns");
      
      println("Smallest Degree: "+ sorted.get(0).adjacentPoints.size());
      println("Largest Degree: "+ sorted.get(sorted.size() - 1).adjacentPoints.size());
      
      startTime = System.nanoTime();
      ArrayList<Integer> ordering = smallestLastOrdering(points);
      endTime = System.nanoTime();
      System.out.println("smallest Last Ordering: " + (endTime - startTime) + " ns");
      
      startTime = System.nanoTime();
      assignColoring(ordering);
      endTime = System.nanoTime();
      System.out.println("Graph Coloring: " + (endTime - startTime) + " ns");
      
      printVertexDegrees();
      println("saved Vertex Degrees");
      
      maxPoint = sorted.get(sorted.size() - 1);
      minPoint = sorted.get(0);
      sortAdjacency = false;
    }
    
    if (discovered && backbone == 0) {
      
      fill(255,100,100,100);
      noStroke();
      ellipse(maxPoint.x, maxPoint.y, maxDist*2, maxDist*2);
      fill(100, 255, 100 , 100);
      noStroke();
      ellipse(minPoint.x, minPoint.y, maxDist*2, maxDist*2);
      fill(10);
    }
    
    
    int num_edges = avg_degree;
    avg_degree = avg_degree / NUM_DOTS;
  
    surface.setTitle(" Nearest neighbor"
      + " | fps "         + String.format("%5.2f", frameRate)
      + " | Average Degree (A) "     + String.format("%d", avg_degree)
      + " | numPoints "   + NUM_DOTS
      + " | numEdges "   + num_edges/2
      + " | maxDist " + maxDist);
     avg_degree = num_edges;
  
}

void connectBackbone(Point p1, int i, float maxDist, ArrayList<Point> points, int color1, int color2, ArrayList<Integer> coveredNodes) {
  final float x = p1.x, y = p1.y;
  final float maxDistSq = maxDist * maxDist;
  if (!coveredNodes.contains(p1.name))
        coveredNodes.add(p1.name);
        
  for (int j = i+1; j < NUM_DOTS; j++) {
    final Point p2 = points.get(j);

    final float dx = Math.abs(p2.x - x);
    if (dx>maxDist) return;
    
    final float dy = Math.abs(p2.y - y);
    if (dy>maxDist) continue;
    
    if (dx*dx + dy*dy < maxDistSq) {
      if (!coveredNodes.contains(p2.name))
        coveredNodes.add(p2.name);
      if (p2.vertexColor == topColors.get(color1) || p2.vertexColor == topColors.get(color2))
        points.get(i).drawLineBasic(points.get(j));
      else {
        // still count for coverage
      }
    }
  }
  
}

void printVertexDegrees() {
   vertexDegrees = createWriter("vertexDegrees.csv");
   Collections.sort(points, new CompareName());
   for (Point p: points) {
      vertexDegrees.println(p.name  + ", " + p.degree + ", " + p.deletedDegree); 
   }
   vertexDegrees.flush();
   vertexDegrees.close();
}

ArrayList<Point> sortAdjacencyListByDegree(ArrayList<Point> points) {
  ArrayList<Point> g1 = new ArrayList<Point>();
  for(Point n: points) {
    //deep copy, because I have a copy constructor in node
    g1.add(new Point(n));
  }
  ArrayList<Point> pointsSorted = g1;
  Collections.sort(pointsSorted, new CompareDegree());
  return pointsSorted;
}

ArrayList<Point> sortAdjacencyListByDegree2(ArrayList<Point> points) {
  Collections.sort(points, new CompareDegree());
  return points;
}

void assignColoring(ArrayList<Integer> ordering) {
  Collections.sort(points, new CompareName());
    for (Integer i: ordering) {
       ArrayList<Integer> takenColors = new ArrayList<Integer>();
       
       for (Integer j: points.get(i).adjacentPoints) {
         int colorIndex = points.get(j).vertexColor;
         if (colorIndex != 0 && !takenColors.contains(colorIndex)) {
            takenColors.add(colorIndex);
         }
       }
              
       for (int j = 1; j < colorList.length-1; j++) {
          if (!takenColors.contains(j)) {
            points.get(i).vertexColor = j;
            if (colorDistribution.get(j) != null) {
                colorDistribution.put(j, colorDistribution.get(j)+1);
            } else {
                colorDistribution.put(j, 1);
            }  
            break;
          }
       }
    }
    printColorDistribution();
}

void DFS(int color1, int color2) {
  for (int i = 0; i < points.size(); i++)
    points.get(i).discovered = 0;
  int flag = 0;
  int size_connected = 0;
  int max = 0;
  int coveredNodes = 0;
  int numEdges = 0;
  
  Collections.sort(points, new CompareName());
  for (int i = 0; i < NUM_DOTS; i++) {
    size_connected = 0;
    if (points.get(i).discovered == 0 && (points.get(i).vertexColor == topColors.get(color1) || points.get(i).vertexColor == topColors.get(color2))) {
      ArrayList<Integer> covered = new ArrayList<Integer>();
      ArrayList<Integer> edges = new ArrayList<Integer>();
      size_connected = DFS2(i, size_connected, color1, color2, covered, edges);
      if (size_connected > max) {
         max = size_connected;
         coveredNodes = covered.size();
         numEdges = edges.size();
      } 
      flag++;
    }
  }
  
  println("Number of connected components: "+ flag);
  println("Largest Component: "+ max);
  println("Number of Vertices in Backbone: " + max);
  println("Percent Coverage of Backbone: " + (float)coveredNodes/NUM_DOTS);
  println("Number of Edges in Backbone: " + (numEdges-1));
}

int DFS2(int v, int size_connected, int color1, int color2, ArrayList<Integer> coveredNodes, ArrayList<Integer> edges) {
  size_connected++;
  points.get(v).discovered = 1;
  edges.add(points.get(v).name);
  if (!coveredNodes.contains(points.get(v).name))
         coveredNodes.add(points.get(v).name);
   
  for(int i = 0; i < points.get(v).adjacentPoints.size(); ++i) {
    if (!coveredNodes.contains(points.get(v).adjacentPoints.get(i)))
         coveredNodes.add(points.get(v).adjacentPoints.get(i));
    if(points.get(points.get(v).adjacentPoints.get(i)).discovered == 0 && (points.get(points.get(v).adjacentPoints.get(i)).vertexColor == topColors.get(color1) || points.get(points.get(v).adjacentPoints.get(i)).vertexColor == topColors.get(color2)))
    {
        size_connected = DFS2(points.get(v).adjacentPoints.get(i), size_connected, color1, color2, coveredNodes, edges);
    }
  
  }
  return size_connected;
}

void printColorDistribution() {
  colorDistOutput = createWriter("colors.csv");
  for (Map.Entry me : colorDistribution.entrySet()) {
    colorDistOutput.print(me.getKey() + ", ");
    colorDistOutput.println(me.getValue());
  }
  colorDistOutput.flush();
  colorDistOutput.close();
  
  ValueComparator bvc = new ValueComparator(colorDistribution);
  TreeMap<Integer, Integer> sorted_map = new TreeMap<Integer, Integer>(bvc);
  sorted_map.putAll(colorDistribution);
  for (Map.Entry<Integer,Integer> me : sorted_map.entrySet()) {
    topColors.add(me.getKey());
  }
  
}

ArrayList<Integer> smallestLastOrdering(ArrayList<Point> points) {
    Collections.sort(points, new CompareName());
    ArrayList<Point> g1 = new ArrayList<Point>();
    for(Point n: points) {
      //deep copy, because I have a copy constructor in node
      g1.add(new Point(n));
    }
    
    ArrayList<Point> sortedList = sortAdjacencyListByDegree(g1);
    Collections.reverse(sortedList);
    
    ArrayList<Integer> ordering = new ArrayList<Integer>();
    int initialSize = sortedList.size();
    for (int i = initialSize - 1; i >= 0; i--) {
     ordering.add(sortedList.get(i).name);
      
     Set<Integer> toRemove = new HashSet<Integer>();
     for(Integer j : sortedList.get(i).adjacentPoints)
       toRemove.add(j);

     for(int j = 0; j < sortedList.size()-1; j++) {
      if(toRemove.contains(sortedList.get(j).name)) {
        sortedList.get(j).adjacentPoints.remove(Integer.valueOf(sortedList.get(i).name));
        sortedList.get(j).degree --;
      }
     }
     points.get(sortedList.get(i).name).deletedDegree = sortedList.get(i).degree;
     sortedList.remove(i);
     if (i > 0) {
       sortedList = sortAdjacencyListByDegree2(sortedList);
       Collections.reverse(sortedList);
     }
    }
    
    Collections.reverse(ordering);
    return ordering;
}

void drawOutline() {
  noFill();
  stroke(255, 0, 0);
  if (status == "Square") {
      //rect(0, 0, width*2, height*2);
  } else if (status == "Disk") {
      ellipse(uniformCirclePosition.x, uniformCirclePosition.y, height, height);
  }
  stroke(FG, DOT_OPAC);
  fill(.5,.5,.8);
}

ArrayList<Point> prepareSquareNodes() {
    points = new ArrayList<Point>();
    points.clear();
    for ( int i = 0; i < NUM_DOTS; i++) {
      Point p = new Point(random(.5, DOT_SPEED));
      p.name = i;
      points.add(p);
    }
      
    return points;
}

ArrayList prepareDiskNodes()
{
  ArrayList points = new ArrayList();
  points.clear();
  for( int i=0; i < NUM_DOTS; ++i )
  {
    Point p = new Point();
    p.name = i;
    points.add( p );
  }
  
  return points;
}

float solveForR() {
  return (float)Math.sqrt((float)A/(NUM_DOTS*Math.PI))*800;
}

float solveForRDisk() {
  return (float)(Math.sqrt((float)A/(NUM_DOTS))*400);
}

void getVerticeDegrees(ArrayList<Point> points) {
  HashMap<Integer, Integer> degrees = new HashMap<Integer, Integer>();
  verticeOutput = createWriter("degrees.csv");
  for (int i = 0; i < points.size(); i++) {
     if (degrees.get(points.get(i).degree) != null){
       degrees.put(points.get(i).degree, degrees.get(points.get(i).degree)+1);
     } else {
        degrees.put(points.get(i).degree, 1); 
     }
  }
  avg_degree = 0;
  for (Map.Entry me : degrees.entrySet()) {
    verticeOutput.print(me.getKey() + ", ");
    verticeOutput.println(me.getValue());
    avg_degree += (int)me.getKey() * (int)me.getValue();
  }
  verticeOutput.flush();
  verticeOutput.close();
  print("saved");
}

void nearestNeighbors(Point p1, int i, float maxDist, ArrayList<Point> points) {
  final float x = p1.x, y = p1.y;
  final float maxDistSq = maxDist * maxDist; 

  for (int j = i+1; j < NUM_DOTS; j++) {
    final Point p2 = points.get(j);

    final float dx = Math.abs(p2.x - x);
    if (dx>maxDist) return;
    
    final float dy = Math.abs(p2.y - y);
    if (dy>maxDist) continue;
    
    if (dx*dx + dy*dy < maxDistSq) {
      points.get(i).drawLine(points.get(j));
    }
  }
}

final class Point extends PVector implements Comparable<Point> {
  final PVector dir = new PVector();
  final float spd;
  int discovered;
  int degree;
  int deletedDegree;
  int name;
  int vertexColor;
  ArrayList<Integer> adjacentPoints;
  

  Point(float speed) {
    spd = speed;
    discovered = 0;
    init();
  }
  
  Point() {
    spd = 0;
    discovered = 0;
    init2();
  }
  
  public Point(Point n)
  {
    this.set(n.x, n.y);
    this.name = n.name;
    this.discovered = n.discovered;
    this.vertexColor = n.vertexColor;
    this.degree = n.degree;
    this.deletedDegree = n.deletedDegree;
    this.spd = n.spd;
    this.adjacentPoints = new ArrayList<Integer>();
    for(Integer i : n.adjacentPoints) {
      this.adjacentPoints.add(new Integer(i));
    }
  }
  
  
  void init2() {
    degree = 0;
    deletedDegree = 0;
    vertexColor = 0;
    discovered = 0;
    adjacentPoints = new ArrayList<Integer>();
    final float a = random(TWO_PI);
    dir.set( spd*cos(a), spd*sin(a), 0 );
    float radius = height / 2.0;
    float theta = random(0, 2 * 3.14159);
    float distance = sqrt(random(0.0, 1.0)) * radius;
    
    float px = distance * cos( theta ) + uniformCirclePosition.x;
    float py = distance * sin( theta ) + uniformCirclePosition.y;
    
    set(px, py);
    
  }

  void init() {
    discovered = 0;
    degree = 0;
    deletedDegree = 0;
    vertexColor = 0;
    final float a = random(TWO_PI);
    dir.set( spd*cos(a), spd*sin(a), 0 );
    set( (int) random(width), (int) random(height), 0 );
    adjacentPoints = new ArrayList<Integer>();
  }

  void update() {
    add(dir);
    if ( isOffScreen() )    init();
  }

  boolean isOffScreen() {
    return x < 0 | x >= width | y < 0 | y >= height;
  }

  void drawPoint() {
    stroke(colorList[vertexColor]);
    fill(colorList[vertexColor]);
    //text(name, x, y);
    if (NUM_DOTS >= 1000)
      ellipse(x, y, 1, 1);
    else   
      ellipse(x, y, 3, 3);
    fill(10);
  }
  
  void drawPointLarge() {
    ellipse(x, y, 5, 65);
  }

  void drawLine(Point other) {
    stroke(FG, DOT_OPAC);
    if (showEdges)
      line(x, y, other.x, other.y);
    if (!adjacentPoints.contains(other.name)) {
      if (!other.adjacentPoints.contains(this.name)) {
         other.adjacentPoints.add(this.name);
         other.degree++;
      }
      adjacentPoints.add(other.name);
      degree++;
    }
  }
  
  void drawLineBasic(Point other) {
    stroke(FG, DOT_OPAC);
    if (showEdges)
      line(x, y, other.x, other.y);
  }

  int compareTo(Point other) {
    return (int) Math.signum(adjacentPoints.size() - other.adjacentPoints.size());
  }
 
}

class CompareTo implements Comparator<PVector>
{
  //@Override
  int compare(PVector v1, PVector v2)
  {
    return (int) Math.signum(v1.x - v2.x);
  }
}

class CompareDegree implements Comparator<Point>
{
  //@Override
  int compare(Point v1, Point v2)
  {
    return (int) Math.signum(v1.degree - v2.degree);
  }
}

class CompareName implements Comparator<Point>
{
  //@Override
  int compare(Point v1, Point v2)
  {
    return (int) Math.signum(v1.name - v2.name);
  }
}

class ValueComparator implements Comparator<Integer> {
    Map<Integer, Integer> base;

    public ValueComparator(Map<Integer, Integer> base) {
        this.base = base;
    }

    // Note: this comparator imposes orderings that are inconsistent with
    // equals.
    public int compare(Integer a, Integer b) {
        if (base.get(a) >= base.get(b)) {
            return -1;
        } else {
            return 1;
        } // returning 0 would merge keys
    }
}

void mouseClicked() {
  showEdges = !showEdges;
}