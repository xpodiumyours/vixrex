import type { MaterialRoundIconName } from "./mockupProfilleri";

type LandingMaterialIconName =
  | MaterialRoundIconName
  | "arrow_forward"
  | "auto_awesome"
  | "check_circle"
  | "explore"
  | "login"
  | "storefront"
  | "visibility";

export function MaterialRoundIcon({
  name,
  size = 20,
  className = "",
}: {
  name: LandingMaterialIconName;
  size?: number;
  className?: string;
}) {
  return (
    <span
      aria-hidden="true"
      className={`material-icons-round select-none leading-none ${className}`}
      style={{ fontSize: size, width: size, height: size }}
    >
      {name}
    </span>
  );
}
