/**
 * Landing/Keşfet yüzeyinin ikon seti.
 *
 * Flutter landing'i Material ikonlarını kullanıyor (envanter §7). Web'de
 * bunlar sunucu bileşenlerinin içinde satır içi SVG olarak yaşar: ikon
 * kütüphanesi eklemek `package.json`'a yeni bir çalışma zamanı bağımlılığı
 * getirirdi, oysa bu işaretlemenin tamamı sunucuda üretiliyor ve tarayıcıya
 * tek bir bayt JavaScript göndermiyor.
 */

type IkonProps = {
  className?: string;
  boyut?: number;
};

function svgOzellikleri(boyut: number, className?: string) {
  return {
    width: boyut,
    height: boyut,
    viewBox: "0 0 24 24",
    fill: "currentColor",
    "aria-hidden": true,
    focusable: false,
    className,
  } as const;
}

/** Material `storefront_rounded` — marka işareti. */
export function StorefrontIkonu({ className, boyut = 20 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M20.2 5.6 19 3.4a1 1 0 0 0-.9-.5H5.9a1 1 0 0 0-.9.5L3.8 5.6A3.4 3.4 0 0 0 3.4 7v.6A2.9 2.9 0 0 0 4.6 10v9a1.5 1.5 0 0 0 1.5 1.5h11.8A1.5 1.5 0 0 0 19.4 19v-9a2.9 2.9 0 0 0 1.2-2.4V7a3.4 3.4 0 0 0-.4-1.4ZM17.4 18.5H6.6V10.4h10.8ZM18.6 7.6a1 1 0 0 1-1 1c-.6 0-1.1-.5-1.1-1V6.5h-1.9v1.1a1 1 0 0 1-1 1c-.6 0-1.1-.5-1.1-1V6.5h-1.9v1.1a1 1 0 0 1-1 1c-.6 0-1.1-.5-1.1-1V6.5H6.5v1.1a1 1 0 0 1-1 1 1 1 0 0 1-1-1V7c0-.2 0-.3.1-.5l1-1.9h12.8l1 1.9c.1.2.2.3.2.5Z" />
    </svg>
  );
}

/** Material `explore` — "Vitrinleri Keşfet". */
export function KesfetIkonu({ className, boyut = 20 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm0 18a8 8 0 1 1 0-16 8 8 0 0 1 0 16Zm2.9-11.5-5.6 2.2a1 1 0 0 0-.6.6l-2.2 5.6a.5.5 0 0 0 .6.6l5.6-2.2a1 1 0 0 0 .6-.6l2.2-5.6a.5.5 0 0 0-.6-.6ZM12 13.1a1.1 1.1 0 1 1 0-2.2 1.1 1.1 0 0 1 0 2.2Z" />
    </svg>
  );
}

/** Material `check_circle` — güven rozetleri ve karşılaştırma listeleri. */
export function OnayIkonu({ className, boyut = 16 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm-2 15-5-5 1.4-1.4L10 14.2l7.6-7.6L19 8Z" />
    </svg>
  );
}

/** Material `arrow_forward` — çağrı butonları. */
export function IleriOkIkonu({ className, boyut = 18 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M12 4 10.6 5.4 16.2 11H4v2h12.2l-5.6 5.6L12 20l8-8Z" />
    </svg>
  );
}

/** Material `bolt_rounded` — özellik kartı 1. */
export function SimsekIkonu({ className, boyut = 26 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M11.3 21.4a.6.6 0 0 1-1-.7l1.6-6H7.7a1 1 0 0 1-.8-1.6l6-8.5a.6.6 0 0 1 1 .7l-1.6 6h4.2a1 1 0 0 1 .8 1.6Z" />
    </svg>
  );
}

/** Material `contact_phone_rounded` — özellik kartı 2. */
export function IletisimIkonu({ className, boyut = 26 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M21 5H3a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h18a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2ZM8.5 8a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm3.7 8H4.8a.8.8 0 0 1-.8-.9c.1-1.4 2.3-2.2 4.5-2.2s4.4.8 4.5 2.2a.8.8 0 0 1-.8.9ZM20 15.5h-4a.8.8 0 0 1 0-1.5h4a.8.8 0 0 1 0 1.5Zm0-3h-4a.8.8 0 0 1 0-1.5h4a.8.8 0 0 1 0 1.5Zm0-3h-4a.8.8 0 0 1 0-1.5h4a.8.8 0 0 1 0 1.5Z" />
    </svg>
  );
}

/** Material `share_rounded` — özellik kartı 3. */
export function PaylasIkonu({ className, boyut = 26 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M18 16.1a3 3 0 0 0-2 .8l-7.1-4.2a3.3 3.3 0 0 0 0-1.4L15.9 7A3 3 0 1 0 15 5c0 .2 0 .5.1.7L8 9.9a3 3 0 1 0 0 4.2l7.2 4.2c0 .2-.1.4-.1.6a2.9 2.9 0 1 0 2.9-2.8Z" />
    </svg>
  );
}

/** Material `edit_note_rounded` — özellik kartı 4. */
export function DuzenleIkonu({ className, boyut = 26 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M3 8h12a1 1 0 0 0 0-2H3a1 1 0 0 0 0 2Zm0 4h9a1 1 0 0 0 0-2H3a1 1 0 0 0 0 2Zm0 4h9a1 1 0 0 0 0-2H3a1 1 0 0 0 0 2Zm18.3-3.4-1-1a.9.9 0 0 0-1.2 0l-.8.8 2.2 2.2.8-.8a.9.9 0 0 0 0-1.2ZM14 19v2h2l5.1-5.1-2.2-2.2Z" />
    </svg>
  );
}

/** Material `check_rounded` — vurgulu karşılaştırma paneli. */
export function TikIkonu({ className, boyut = 18 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4Z" />
    </svg>
  );
}

/** Material `close_rounded` — karşılaştırmada "bu senin işin" satırları. */
export function CarpiIkonu({ className, boyut = 18 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M18.3 5.7 12 12l6.3 6.3-1.4 1.4L10.6 13.4 5.7 18.3 4.3 16.9 10.6 12 4.3 7.1l1.4-1.4L10.6 10.6l6.3-6.3Z" />
    </svg>
  );
}

/** Material `arrow_downward_rounded` / `arrow_forward_rounded` — yön oku. */
export function YonOkuIkonu({ className, boyut = 22 }: IkonProps) {
  return (
    <svg {...svgOzellikleri(boyut, className)}>
      <path d="M12 4 10.6 5.4 16.2 11H4v2h12.2l-5.6 5.6L12 20l8-8Z" />
    </svg>
  );
}
