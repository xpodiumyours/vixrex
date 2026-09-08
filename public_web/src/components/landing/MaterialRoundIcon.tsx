import type { MaterialRoundIconName } from "./mockupProfilleri";

export function MaterialRoundIcon({
  name,
  size = 20,
  className = "",
}: {
  name: MaterialRoundIconName | "auto_awesome" | "storefront" | "visibility" | "arrow_forward";
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
