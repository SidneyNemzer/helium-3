import React, {
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { Object3D } from "three";

type Props = {
  children: React.ReactNode;
  hide?: boolean;
};

const noop = () => {};

const Context = React.createContext<{
  add: (o: Object3D) => void;
  remove: (o: Object3D) => void;
}>({ add: noop, remove: noop });

/**
 * ONLY PASS ONE react three fiber CHILD ELEMENT otherwise this will probably
 * throw weird errors.
 */
export const Outline = React.forwardRef<unknown, Props>(
  ({ children, hide = false }, parentRef) => {
    // TODO try to work with and array of children

    const ref = useRef<Object3D>();
    const { add, remove } = useContext(Context);

    useEffect(() => {
      if (!ref.current) {
        throw new Error("Outline: ran effect before ref resolved");
      }

      if (!hide) {
        add(ref.current);
      } else {
        remove(ref.current);
      }
    }, [hide]);

    const child = React.Children.only(children);

    if (!React.isValidElement(child)) {
      throw new Error(
        "only a single react three fiber element should be given as a child to <Outline>"
      );
    }

    return React.cloneElement(child, {
      ref: (e: Object3D) => {
        ref.current = e;

        if (typeof parentRef === "function") {
          parentRef(e);
        } else if (parentRef) {
          parentRef.current = e;
        }
      },
    });
  }
);

const useOutlined = () => {
  const [outlined, setOutlined] = useState<Set<Object3D>>(() => new Set());

  const context = useMemo(
    () => ({
      add: (o: Object3D) => setOutlined((set) => new Set(set).add(o)),
      remove: (o: Object3D) =>
        setOutlined((old) => {
          const set = new Set(old);
          set.delete(o);
          return set;
        }),
    }),
    []
  );

  const Provider: React.FC<{ children: ReactNode }> = useMemo(
    () =>
      ({ children }) => {
        return <Context.Provider value={context}>{children}</Context.Provider>;
      },
    []
  );

  return [Provider, useMemo(() => Array.from(outlined), [outlined])];
};
