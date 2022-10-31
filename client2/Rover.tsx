import React from "react";
import { useGLTF } from "@react-three/drei";
import { animated, WithAnimated } from "@react-spring/three";

import { ThreeEventHandler, Vector3Array } from "./types/three";

import roverGlbUrl from "./rover.glb";

type Props = {
  position: any;
  // position: [number, number, number];
  rotationY: number;
  onClick: ThreeEventHandler;
  onPointerOver: ThreeEventHandler;
  onPointerOut: ThreeEventHandler;
};

const Rover: React.FC<Props> = ({
  position,
  rotationY,
  onClick,
  onPointerOver,
  onPointerOut,
}) => {
  const roverGlb = useGLTF(roverGlbUrl);

  return (
    <primitive
      position={position}
      rotation-y={rotationY}
      onClick={onClick}
      onPointerOver={onPointerOver}
      onPointerOut={onPointerOut}
      object={roverGlb.scene}
    />
  );
};

export default animated(Rover) as any;
