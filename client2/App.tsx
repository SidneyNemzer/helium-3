import React, { useEffect, useMemo, useState } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { DomEvent } from "@react-three/fiber/dist/declarations/src/core/events";
import { useGLTF } from "@react-three/drei";
import { Color, Euler, MathUtils, Object3D, Vector2 } from "three";
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass";
import { OutlinePass } from "three/examples/jsm/postprocessing/OutlinePass";
import { Global, css } from "@emotion/react";
import { animated, easings, useSpring } from "@react-spring/three";

import roverGlbUrl from "./rover.glb";

const BACKGROUND_COLOR = new Color("#1f1f1f");
const GROUND_COLOR = new Color("#8d8d8d");
const GRID_COLOR = new Color("black");

const FIELD_OF_VIEW = 75;

const ROTATION_90_DEGREES = new Euler(-MathUtils.degToRad(90));

export const App = () => {
  // const { rotation } = useSpring({
  //   loop: { reverse: true },
  //   to: { rotation: Math.PI * 2 },
  //   from: { rotation: 0 },
  //   config: { duration: 5000, easing: easings.easeInOutQuart },
  // });

  const [{ rotation }, spring] = useSpring(() => ({
    // loop: { reverse: true },
    // to: { rotation: Math.PI * 2 },
    from: { rotation: 0 },
    config: { duration: 1000, easing: easings.easeInOutQuart },
  }));

  const [hovered, setHovered] = useState<Object3D>();

  const handleClick = () => {
    if (rotation.get() === 0) {
      spring.start({ rotation: Math.PI });
    } else {
      spring.start({ rotation: 0 });
    }
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
        camera={{ position: [0, 5, 5], fov: FIELD_OF_VIEW }}
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
        <Effects outline={outline} />
        <color attach="background" args={[BACKGROUND_COLOR]} />
        <animated.group rotation-y={rotation}>
          <mesh rotation={ROTATION_90_DEGREES}>
            <planeGeometry args={[10, 10]} />
            <meshBasicMaterial color={GROUND_COLOR} />
          </mesh>
          <gridHelper args={[10, 10, GRID_COLOR, GRID_COLOR]} />
          <Rover
            onClick={handleClick}
            onPointerOver={handlePointerOver}
            onPointerOut={handlePointerOut}
          />
        </animated.group>
        <ambientLight color="white" intensity={0.5} />
        <directionalLight color="white" intensity={0.8} />
      </Canvas>
      <Global styles={globalStyles} />
    </>
  );
};

// TODO consider using Effects from @react-three/drei
const Effects: React.FC<{ outline: Object3D[] }> = ({ outline }) => {
  const { gl, scene, camera, size } = useThree();

  const [[composer, outlinePass]] = useState(() => {
    console.log(gl.getRenderTarget());
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
