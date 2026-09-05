import type { VixrexMatchClass } from "./vixrexIntentResolver";

export const VIXREX_DECISION_CONTRACT_VERSION = 1 as const;

export type VixrexDecisionKind =
  | "not_understood"
  | "needs_clarification"
  | "needs_special_flow"
  | "validated_action"
  | "validated_action_group"
  | "blocked";

/**
 * `pending_slot`, iki turlu konuşmada alan önceki mesajda kesin olarak
 * seçilmişken ikinci mesaj yalnız değeri taşıdığında kullanılır. Bu bir
 * matcher skoru değildir; sahte bir `exact_*` sonucu üretmemek için açıkça
 * ayrı tutulur. 5.4 pending envelope bunu kanonik state'e taşıyacaktır.
 */
export type VixrexActionMatchClass = VixrexMatchClass | "pending_slot";

export interface VixrexValidatedAction {
  contractVersion: typeof VIXREX_DECISION_CONTRACT_VERSION;
  domain: "storefront";
  actionType: "set_field";
  fieldKey: string;
  normalizedValue: string | number | boolean | null;
  matchClass: VixrexActionMatchClass;
}

export function createValidatedAction(params: {
  fieldKey: string;
  normalizedValue: unknown;
  matchClass: VixrexActionMatchClass;
}): VixrexValidatedAction {
  const value = params.normalizedValue;
  if (
    value !== null &&
    typeof value !== "string" &&
    typeof value !== "number" &&
    typeof value !== "boolean"
  ) {
    throw new TypeError("validated_action normalizedValue desteklenmeyen tipte.");
  }

  return {
    contractVersion: VIXREX_DECISION_CONTRACT_VERSION,
    domain: "storefront",
    actionType: "set_field",
    fieldKey: params.fieldKey,
    normalizedValue: value,
    matchClass: params.matchClass,
  };
}
