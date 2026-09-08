import type { MaterialRoundIconName } from "./mockupProfilleri";

type LandingMaterialIconName =
  | MaterialRoundIconName
  | "arrow_downward"
  | "arrow_forward"
  | "auto_awesome"
  | "bakery_dining"
  | "bolt"
  | "business_center"
  | "chair"
  | "chat_bubble_outline"
  | "check"
  | "check_circle"
  | "clean_hands"
  | "code_off"
  | "contact_phone"
  | "credit_card_off"
  | "devices"
  | "explore"
  | "face"
  | "face_retouching_natural"
  | "fitness_center"
  | "forum"
  | "hub"
  | "inventory_2"
  | "language"
  | "local_car_wash"
  | "local_mall"
  | "local_pharmacy"
  | "login"
  | "medical_services"
  | "percent"
  | "pets"
  | "school"
  | "share"
  | "shopping_basket"
  | "storefront"
  | "support_agent"
  | "tune"
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
