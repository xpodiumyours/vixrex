export function taslakUrunMu(urun: { is_visible?: boolean | null }): boolean {
  return urun.is_visible === false;
}
