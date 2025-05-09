var container, stats;
var camera, scene, renderer;
var group, shapes = [];
init();

function init(){
  container = document.createElement( 'div' );
  document.body.appendChild( container );
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera( 50, window.innerWidth / window.innerHeight, 1, 1000 );
  camera.position.set( 0, 150, 500 );
  scene.add( camera );

  var light = new THREE.DirectionalLight(0x9955ff, 2);
  light.position.x = -500;
  light.position.y = 500;
  camera.add( light );
  
  var light = new THREE.DirectionalLight(0x9955ff, 1);
  light.position.x = 500;
  light.position.y = -500;
  light.position.z = -150;
  camera.add( light );
  
  scene.background = new THREE.Color( '#993355' );
 
  var x = -25, y = -250;
  var heartShape = new THREE.Shape();
  heartShape.moveTo( x + 25, y + 25 );
  heartShape.bezierCurveTo( x + 25, y + 25, x + 20, y, x, y );
  heartShape.bezierCurveTo( x - 30, y, x - 30, y + 35,x - 30,y + 35 );
  heartShape.bezierCurveTo( x - 30, y + 55, x - 10, y + 77, x + 25, y + 95 );
  heartShape.bezierCurveTo( x + 60, y + 77, x + 80, y + 55, x + 80, y + 35 );
  heartShape.bezierCurveTo( x + 80, y + 35, x + 80, y, x + 50, y );
  heartShape.bezierCurveTo( x + 35, y, x + 25, y + 25, x + 25, y + 25 );
  
  var extrudeSettings = { amount: 1, bevelEnabled: true, bevelSegments: 20, steps: 2, bevelSize: 20, bevelThickness: 10 };
  
  for (var i=-window.innerWidth/2; i<window.innerWidth/2; i+=60+Math.random()*50){
    for (var j=0; j<window.innerHeight; j+=60+Math.random()*50){
      addShape( heartShape,  extrudeSettings, '#ff0022',   i, j, 0, 
               Math.random()*0.8, Math.random()*0.8, Math.PI, 0.1+Math.random()*0.3 );
    }
  }
  
  renderer = new THREE.WebGLRenderer( { antialias: true } );
  renderer.setPixelRatio( window.devicePixelRatio );
  renderer.setSize( window.innerWidth, window.innerHeight );
  container.appendChild( renderer.domElement );

  render();
  
} 

function addShape( shape, extrudeSettings, color, x, y, z, rx, ry, rz, s ) {
  var geometry = new THREE.ExtrudeGeometry( shape, extrudeSettings );
  var mesh = new THREE.Mesh( geometry, new THREE.MeshPhongMaterial( { color: color } ) );
  mesh.position.set( x+25, y-50, z );
  mesh.rotation.set( rx, ry, rz );
  mesh.scale.set( s, s, s );	
  shapes.push({shape: mesh, x: Math.random(), y: Math.random(), z: Math.random()});
  scene.add(mesh);
}

function animate() {
  var speed = 0.05;
  shapes.forEach(el => {
    el.shape.rotation.x += el.x * speed;
    el.shape.rotation.y += el.y * speed;
    el.shape.rotation.z += el.z * speed;
  });
}

function render() {
    requestAnimationFrame(render);
    animate();
    renderer.render(scene, camera);
}