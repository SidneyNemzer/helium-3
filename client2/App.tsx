import React, { useEffect, useMemo, useState, useRef } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { DomEvent } from "@react-three/fiber/dist/declarations/src/core/events";
import { OrbitControls, useGLTF } from "@react-three/drei";
import {
  Camera,
  Color,
  Euler,
  MathUtils,
  Object3D,
  Vector2,
  Vector3,
} from "three";
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
import { OutlinePass } from "three/examples/jsm/postprocessing/OutlinePass";
import { Global, css } from "@emotion/react";
import {
  animated,
  easings,
  useSpring,
  config,
  useChain,
  useSpringRef,
} from "@react-spring/three";

import roverGlbUrl from "./rover.glb";

const BACKGROUND_COLOR = new Color("#1f1f1f");
const GROUND_COLOR = new Color("#8d8d8d");
const GRID_COLOR = new Color("black");

const CAMERA_POSITION = new Vector3(-1.0, 13.9, 8.1);
const CAMERA_ROTATION = new Euler(-1.234, 0.05616, 0.15895);
const FIELD_OF_VIEW = 75;

const ROTATION_90_DEGREES = new Euler(-MathUtils.degToRad(90));

/**
 * @returns the angle starting at v1 looking at v2, in radians
 */
const angleTo = (v1: Vector3, v2: Vector3): number => {
  return Math.atan2(v1.z - v2.z, v2.x - v1.x);
};

export const App = () => {
  // const { rotation } = useSpring({
  //   loop: { reverse: true },
  //   to: { rotation: Math.PI * 2 },
  //   from: { rotation: 0 },
  //   config: { duration: 5000, easing: easings.easeInOutQuart },
  // });

  const [targetDestiation, setTargetDestination] = useState<
    [number, number, number]
  >([0, 0, 0]);
  const [targetRotation, setTargetRotation] = useState(0);

  // const [{ rotation }] = useSpring(() => ({
  // loop: { reverse: true },
  // to: { rotation: Math.PI * 2 },
  // from: { rotation: 0 },
  // config: { duration: 1000, easing: easings.easeInOutQuart },
  // }));

  const rotationRef = useSpringRef();
  const { rotation } = useSpring({
    to: { rotation: targetRotation },
    config: { duration: 1000, easing: easings.easeInOutQuart },
    ref: rotationRef,
  });

  const positionRef = useSpringRef();
  const { position } = useSpring({
    to: { position: targetDestiation },
    config: { duration: 2000, easing: easings.easeInOutQuart },
    delay: 500,
    ref: positionRef,
  });

  useChain([rotationRef, positionRef]);

  const [hovered, setHovered] = useState<Object3D>();

  const cameraRef = useRef<Camera>(null);
  const copyPosition = () => {
    if (!cameraRef.current) {
      return;
    }

    console.log(
      cameraRef.current.position,
      cameraRef.current.rotation,
      cameraRef.current
    );
  };

  const handleClick = () => {
    // if (rotation.get() === 0) {
    //   spring.start({ rotation: Math.PI });
    // } else {
    //   spring.start({ rotation: 0 });
    // }
    const destination: [number, number, number] = [
      MathUtils.randInt(5, -5),
      0,
      MathUtils.randInt(5, -5),
    ];
    const locationVector = new Vector3(...position.get());
    const destinationVector = new Vector3(...destination);
    // TODO fix robot rotation in GLB, remove `+ Math.PI`
    let angle = angleTo(locationVector, destinationVector) + Math.PI;
    setTargetRotation(angle);
    setTargetDestination(destination);
  };

  const handlePointerOver: ThreeEventHandler = ({ object }) => {
    setHovered(object);
  };

  const handlePointerOut: ThreeEventHandler = () => {
    setHovered(undefined);
  };

  const outline = useMemo(() => (hovered ? [hovered] : []), [hovered]);

  return (
    <>
      <Canvas
        camera={{
          position: CAMERA_POSITION,
          rotation: CAMERA_ROTATION,
          fov: FIELD_OF_VIEW,
        }}
        // linear and flat disable color correction from r3f, to match the
        // threejs defaults
        linear
        flat
        // when legacy is falsy, r3f sets `THREE.ColorManagement.legacyMode =
        // false`. This causes threejs to map some colors to srgb instead of the
        // default srgb-linear. r3f changes this setting when <Canvas> is
        // rendered, but some colors may have been constructed before rendering
        // leading to inconsistent colors.
        legacy
      >
        {/* <Animator /> */}
        {/* TODO orbitcontrols change initial camera rotation */}
        <OrbitControls enableDamping enablePan enableZoom />
        <Effects outline={outline} />
        <color attach="background" args={[BACKGROUND_COLOR]} />
        <animated.group>
          <mesh rotation={ROTATION_90_DEGREES}>
            <planeGeometry args={[20, 20]} />
            <meshBasicMaterial color={GROUND_COLOR} />
          </mesh>
          <gridHelper args={[20, 20, GRID_COLOR, GRID_COLOR]} />

          <animated.group position={position} rotation-y={rotation}>
            <Rover
              onClick={handleClick}
              onPointerOver={handlePointerOver}
              onPointerOut={handlePointerOut}
            />
          </animated.group>
        </animated.group>
        <ambientLight color="white" intensity={0.5} />
        <directionalLight color="white" intensity={0.8} />
        <CameraRef ref={cameraRef} />
      </Canvas>
      <div style={{ position: "absolute", top: 0 }}>
        <button onClick={copyPosition}>Copy Camera Position</button>
      </div>
      <Global styles={globalStyles} />
    </>
  );
};

const CameraRef = React.forwardRef<Camera>(({}, ref) => {
  useThree(({ camera }) => {
    if (typeof ref === "function") {
      ref(camera);
    } else if (ref) {
      ref.current = camera;
    }
  });

  return null;
});

// TODO consider using Effects from @react-three/drei
const Effects: React.FC<{ outline: Object3D[] }> = ({ outline }) => {
  const { gl, scene, camera, size } = useThree();

  const [[composer, outlinePass]] = useState(() => {
    const size = gl.getSize(new Vector2());

    const composer = new EffectComposer(gl);

    composer.addPass(new RenderPass(scene, camera));

    // TODO outline lowers resolution of scene
    const outlinePass = new OutlinePass(
      new Vector2(size.width * gl.pixelRatio, size.height * gl.pixelRatio),
      scene,
      camera
    );
    composer.addPass(outlinePass);

    return [composer, outlinePass] as const;
  });

  useEffect(() => {
    composer.setSize(size.width, size.height);
  }, [composer, size]);

  useEffect(() => {
    outlinePass.selectedObjects = outline;
  }, [outline, outlinePass]);

  useFrame(() => {
    composer.render();
  }, 1);

  return null;
};

type ThreeEvent = DomEvent & {
  object: Object3D;
};

type ThreeEventHandler = (event: ThreeEvent) => void;

const Rover: React.FC<{
  onClick: ThreeEventHandler;
  onPointerOver: ThreeEventHandler;
  onPointerOut: ThreeEventHandler;
}> = ({ onClick, onPointerOver, onPointerOut }) => {
  const roverGlb = useGLTF(roverGlbUrl);

  return (
    <primitive
      onClick={onClick}
      onPointerOver={onPointerOver}
      onPointerOut={onPointerOut}
      object={roverGlb.scene}
    />
  );
};

const globalStyles = css`
  html,
  body,
  #root {
    height: 100%;
    margin: 0;
  }
`;

export default App;
