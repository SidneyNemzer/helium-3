import { DomEvent } from "@react-three/fiber/dist/declarations/src/core/events";
import { Object3D } from "three";

export type ThreeEvent = DomEvent & {
  object: Object3D;
};

export type ThreeEventHandler = (event: ThreeEvent) => void;

export type Vector3Array = [number, number, number];
