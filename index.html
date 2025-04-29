<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Infinite City Demo</title>
  <style>
    body { margin: 0; overflow: hidden; }
    canvas { display: block; }
  </style>
</head>
<body>
<script type="module">
import * as THREE from 'https://unpkg.com/three@0.153.0/build/three.module.js';
import { OrbitControls } from 'https://unpkg.com/three@0.153.0/examples/jsm/controls/OrbitControls.js';

const GRID_SIZE  = 20, BLOCK_SIZE = 10;
const scene = new THREE.Scene();
scene.fog = new THREE.Fog(0xaaaaaa, BLOCK_SIZE*5, BLOCK_SIZE*GRID_SIZE);

const camera = new THREE.PerspectiveCamera(60, innerWidth/innerHeight, 0.1, 10000);
camera.position.set(0,50,100);

const renderer = new THREE.WebGLRenderer({ antialias:true });
renderer.setSize(innerWidth, innerHeight);
document.body.appendChild(renderer.domElement);

window.addEventListener('resize', ()=>{
  camera.aspect = innerWidth/innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

const controls = new OrbitControls(camera, renderer.domElement);

const blocks = [];
function createBlock(ix, iz){
  const h = Math.random()*20+5;
  const geo = new THREE.BoxGeometry(BLOCK_SIZE, h, BLOCK_SIZE);
  const mat = new THREE.MeshStandardMaterial({ color: Math.random()*0xffffff });
  const m   = new THREE.Mesh(geo, mat);
  m.position.set(
    (ix-GRID_SIZE/2)*BLOCK_SIZE,
    h/2,
    (iz-GRID_SIZE/2)*BLOCK_SIZE
  );
  scene.add(m);
  blocks.push(m);
}
for(let i=0;i<GRID_SIZE;i++)
  for(let j=0;j<GRID_SIZE;j++)
    createBlock(i,j);

scene.add(new THREE.AmbientLight(0x666666));
const dir = new THREE.DirectionalLight(0xffffff,1);
dir.position.set(100,200,100);
scene.add(dir);

const keys={}, SPEED=1;
addEventListener('keydown', e=>keys[e.code]=true);
addEventListener('keyup',   e=>keys[e.code]=false);

function updateMovement(){
  if(keys['KeyW']||keys['ArrowUp'])   camera.position.z -= SPEED;
  if(keys['KeyS']||keys['ArrowDown']) camera.position.z += SPEED;
  if(keys['KeyA']||keys['ArrowLeft']) camera.position.x -= SPEED;
  if(keys['KeyD']||keys['ArrowRight'])camera.position.x += SPEED;
}

function wrapBlocks(){
  const half = (GRID_SIZE/2)*BLOCK_SIZE;
  if(camera.position.x >  half){
    blocks.forEach(b=>b.position.x-=GRID_SIZE*BLOCK_SIZE);
    camera.position.x -= GRID_SIZE*BLOCK_SIZE;
  }
  if(camera.position.x < -half){
    blocks.forEach(b=>b.position.x+=GRID_SIZE*BLOCK_SIZE);
    camera.position.x += GRID_SIZE*BLOCK_SIZE;
  }
  if(camera.position.z >  half){
    blocks.forEach(b=>b.position.z-=GRID_SIZE*BLOCK_SIZE);
    camera.position.z -= GRID_SIZE*BLOCK_SIZE;
  }
  if(camera.position.z < -half){
    blocks.forEach(b=>b.position.z+=GRID_SIZE*BLOCK_SIZE);
    camera.position.z += GRID_SIZE*BLOCK_SIZE;
  }
}

(function animate(){
  requestAnimationFrame(animate);
  updateMovement();
  wrapBlocks();
  controls.update();
  renderer.render(scene,camera);
})();
</script>
</body>
</html>
