"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

interface Offering {
  id: string;
  title: string;
  description?: string;
  price?: string;
  durationMinutes?: number;
  isBookable?: boolean;
}

interface Slot {
  time: string;
  capacity_total: number;
  capacity_used: number;
  slots_left: number;
  confirmed_names: string[];
  has_pending: boolean;
}

interface BookingWizardClientProps {
  store: {
    slug: string;
    name: string;
    offerings: unknown;
  };
}

export default function BookingWizardClient({ store }: BookingWizardClientProps) {
  const [step, setStep] = useState(1);
  const [selectedService, setSelectedService] = useState<Offering | null>(null);
  const [selectedDate, setSelectedDate] = useState<string>("");
  const [selectedSlot, setSelectedSlot] = useState<Slot | null>(null);
  const [slots, setSlots] = useState<Slot[]>([]);
  const [loadingSlots, setLoadingSlots] = useState(false);

  // Customer Info
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [notes, setNotes] = useState("");
  
  // Submit state
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successData, setSuccessData] = useState<{ appointmentId: string; token: string } | null>(null);

  // Parse offerings
  const rawOfferings: Offering[] = Array.isArray(store.offerings)
    ? store.offerings
    : typeof store.offerings === "string"
    ? (() => {
        try {
          return JSON.parse(store.offerings);
        } catch {
          return [];
        }
      })()
    : [];

  // Filter bookable offerings. Fallback to all if none are marked bookable
  const bookableServices = rawOfferings.filter(o => o.isBookable !== false);
  const servicesList = bookableServices.length > 0 ? bookableServices : rawOfferings;

  // Generate next 30 days
  const getNext30Days = () => {
    const dates = [];
    const today = new Date();
    for (let i = 0; i < 30; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      dates.push(date);
    }
    return dates;
  };

  const datesList = getNext30Days();

  // Load slots when date changes
  useEffect(() => {
    if (!selectedDate) return;

    async function fetchSlots() {
      setLoadingSlots(true);
      setErrorMessage("");
      try {
        const { data, error } = await supabase.rpc("get_public_booking_slots", {
          p_store_slug: store.slug,
          p_date: selectedDate,
        });

        if (error) throw error;
        
        // Parse result
        const fetchedSlots: Slot[] = Array.isArray(data) 
          ? data 
          : typeof data === "string" 
          ? JSON.parse(data) 
          : [];
        setSlots(fetchedSlots);
      } catch (err: unknown) {
        console.error("Error fetching slots:", err);
        setErrorMessage("Müsait saatler yüklenirken bir hata oluştu.");
      } finally {
        setLoadingSlots(false);
      }
    }

    fetchSlots();
  }, [selectedDate, store.slug]);

  // Format date helper (TR locale)
  const formatDateTR = (date: Date) => {
    return date.toLocaleDateString("tr-TR", { weekday: "long", day: "numeric", month: "long" });
  };

  const formatDateISO = (date: Date) => {
    return date.toISOString().split("T")[0];
  };

  // Submit appointment request
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedService || !selectedDate || !selectedSlot) return;

    // Validate inputs
    if (name.trim().length < 3) {
      setErrorMessage("Lütfen geçerli bir isim giriniz (en az 3 karakter).");
      return;
    }

    const cleanPhone = phone.replace(/[^0-9]/g, "");
    // Türk GSM: 05xx xxx xx xx (10 hane) veya 905xx... (12 hane) veya uluslararası +90 (12 hane)
    const isTurkishGsm =
      (cleanPhone.length === 10 && /^5[0-9]{9}$/.test(cleanPhone)) ||
      (cleanPhone.length === 11 && /^05[0-9]{9}$/.test(cleanPhone)) ||
      (cleanPhone.length === 12 && /^905[0-9]{9}$/.test(cleanPhone));
    if (!isTurkishGsm) {
      setErrorMessage("Lütfen geçerli bir Türk GSM numarası giriniz (örn: 0555 123 45 67).");
      return;
    }

    setIsSubmitting(true);
    setErrorMessage("");

    try {
      // Build ISO appointment time: e.g. "2026-06-22T13:00:00Z"
      // Combine date string and slot time
      const dateTimeStr = `${selectedDate}T${selectedSlot.time}:00`;
      
      const { data, error } = await supabase.rpc("create_appointment_request", {
        p_store_slug: store.slug,
        p_customer_name: name.trim(),
        p_customer_phone: cleanPhone,
        p_customer_notes: notes.trim(),
        p_service_title: selectedService.title,
        p_service_price: selectedService.price || "",
        p_service_duration: selectedService.durationMinutes || 30,
        p_appointment_time: new Date(dateTimeStr).toISOString(),
      });

      if (error) {
        if (error.message.includes("DAILY_LIMIT_EXCEEDED")) {
          throw new Error("Aynı telefon numarası ile günlük randevu limitine ulaştınız (Maks 5).");
        } else if (error.message.includes("CAPACITY_FULL")) {
          throw new Error("Seçtiğiniz saatte kapasite dolmuştur. Lütfen başka bir saat seçin.");
        } else if (error.message.includes("DATE_TIME_BLOCKED")) {
          throw new Error("Seçtiğiniz saat aralığı işletme tarafından kapatılmıştır.");
        } else {
          throw error;
        }
      }

      // Save to localStorage
      const apptData = {
        storeSlug: store.slug,
        storeName: store.name,
        appointmentId: data.appointment_id,
        token: data.token,
        serviceTitle: selectedService.title,
        appointmentTime: dateTimeStr,
      };

      const existingApptsJson = localStorage.getItem("vixrex_appointments") || "[]";
      const existingAppts = JSON.parse(existingApptsJson);
      existingAppts.push(apptData);
      localStorage.setItem("vixrex_appointments", JSON.stringify(existingAppts));

      setSuccessData({
        appointmentId: data.appointment_id,
        token: data.token,
      });
      setStep(5);
    } catch (err: unknown) {
      console.error("Error creating appointment:", err);
      const errMsg = err instanceof Error ? err.message : "Randevu talebi oluşturulurken bir hata oluştu.";
      setErrorMessage(errMsg);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Success view
  if (step === 5 && successData) {
    const trackingUrl = `/v/${store.slug}/randevu/${successData.token}`;
    const cleanPhone = phone.replace(/[^0-9]/g, "");
    const maskedPhone = cleanPhone.substring(0, 3) + "***" + cleanPhone.substring(cleanPhone.length - 4);
    
    return (
      <div className="card space-y-6 text-center animate-fade-in bg-white dark:bg-[#131A22] border-emerald-100 dark:border-emerald-950">
        <div className="w-16 h-16 bg-emerald-500/10 text-emerald-500 rounded-full flex items-center justify-center mx-auto">
          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
        </div>
        <div className="space-y-2">
          <h2 className="text-xl font-extrabold text-emerald-600 dark:text-emerald-400">Randevu Talebiniz Alındı</h2>
          <p className="text-sm text-[#475569] dark:text-[#CBD5E1]">
            İşletme randevu talebinizi inceleyip onayladığında veya reddettiğinde bu sayfadan canlı takip edebilirsiniz.
          </p>
        </div>

        <div className="bg-slate-50 dark:bg-slate-900/50 p-4 rounded-xl border border-slate-100 dark:border-slate-800 text-left space-y-2 text-xs">
          <div><span className="font-bold text-[#64748B]">Hizmet:</span> {selectedService?.title}</div>
          <div><span className="font-bold text-[#64748B]">Tarih:</span> {selectedDate} · {selectedSlot?.time}</div>
          <div><span className="font-bold text-[#64748B]">Müşteri:</span> {name.substring(0, 1)}*** {name.split(" ").slice(1).map(p => p[0] + "***").join(" ")}</div>
          <div><span className="font-bold text-[#64748B]">Telefon:</span> {maskedPhone}</div>
        </div>

        <div className="space-y-3">
          <Link href={trackingUrl} className="btn-primary w-full py-3 rounded-xl font-bold text-sm">
            Talebi Canlı Takip Et
          </Link>
          <p className="text-[10px] text-[#64748B] dark:text-[#94A3B8]">
            Bu bağlantı yerel tarayıcınızın geçmişine kaydedilmiştir. Randevu durumunu dilediğiniz zaman bu linkten kontrol edebilirsiniz.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Step Indicator */}
      <div className="flex items-center justify-between text-xs font-bold text-[#64748B] dark:text-[#94A3B8] px-1">
        <span>Adım {step} / 4</span>
        <span>
          {step === 1 && "Hizmet Seçimi"}
          {step === 2 && "Tarih Seçimi"}
          {step === 3 && "Saat Seçimi"}
          {step === 4 && "İletişim Bilgileri"}
        </span>
      </div>
      <div className="w-full bg-slate-200 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden">
        <div 
          className="bg-brand-gradient h-full transition-all duration-300"
          style={{ width: `${(step / 4) * 100}%` }}
        />
      </div>

      {errorMessage && (
        <div className="p-4 bg-red-500/10 border border-red-500/20 text-red-600 dark:text-red-400 text-xs font-semibold rounded-xl">
          {errorMessage}
        </div>
      )}

      {/* STEP 1: Service Selection */}
      {step === 1 && (
        <div className="card space-y-4 bg-white dark:bg-[#131A22]">
          <h2 className="text-base font-extrabold">Hangi hizmeti almak istersiniz?</h2>
          <div className="grid gap-3">
            {servicesList.length > 0 ? (
              servicesList.map((service, index) => (
                <button
                  key={service.id || index}
                  onClick={() => {
                    setSelectedService(service);
                    setStep(2);
                  }}
                  className="w-full text-left p-4 border border-[#D0E4E8] dark:border-[#243141] rounded-xl hover:border-[#10D8D8] focus:outline-none focus:ring-2 focus:ring-[#10D8D8]/20 flex justify-between items-center bg-slate-50/50 dark:bg-slate-900/30 transition-all hover:-translate-y-0.5"
                >
                  <div className="space-y-1">
                    <h3 className="font-extrabold text-sm text-[#182028] dark:text-white">{service.title}</h3>
                    {service.description && (
                      <p className="text-xs text-[#64748B] dark:text-[#94A3B8] line-clamp-2">{service.description}</p>
                    )}
                    {service.durationMinutes && (
                      <span className="inline-block text-[10px] bg-[#10D8D8]/10 text-[#0EA8B0] px-1.5 py-0.5 rounded font-bold">
                        {service.durationMinutes} dk
                      </span>
                    )}
                  </div>
                  <div className="text-sm font-extrabold text-[#38A0E4] shrink-0">
                    {service.price || "Fiyat Sorun"}
                  </div>
                </button>
              ))
            ) : (
              <p className="text-sm text-[#64748B] text-center py-6">Tanımlanmış randevulu hizmet bulunamadı.</p>
            )}
          </div>
        </div>
      )}

      {/* STEP 2: Date Selection */}
      {step === 2 && (
        <div className="card space-y-4 bg-white dark:bg-[#131A22]">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-extrabold">Bir randevu tarihi seçin</h2>
            <button onClick={() => setStep(1)} className="text-xs font-bold text-[#64748B] hover:text-[#10D8D8]">
              Geri
            </button>
          </div>
          <div className="max-h-[350px] overflow-y-auto space-y-2 pr-1">
            {datesList.map((date) => {
              const isoDate = formatDateTR(date);
              const dateVal = formatDateISO(date);
              const isSelected = selectedDate === dateVal;

              return (
                <button
                  key={dateVal}
                  onClick={() => {
                    setSelectedDate(dateVal);
                    setStep(3);
                  }}
                  className={`w-full text-left p-3.5 border rounded-xl font-bold text-xs transition-all flex items-center justify-between ${
                    isSelected 
                      ? "border-[#10D8D8] bg-[#10D8D8]/5 text-[#0EA8B0]" 
                      : "border-[#D0E4E8] dark:border-[#243141] hover:border-[#10D8D8] bg-slate-50/50 dark:bg-slate-900/30"
                  }`}
                >
                  <span>{isoDate}</span>
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="9 18 15 12 9 6"/></svg>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* STEP 3: Time Slot Selection */}
      {step === 3 && (
        <div className="card space-y-4 bg-white dark:bg-[#131A22]">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-extrabold">Bir saat dilimi seçin</h2>
            <div className="flex gap-3">
              <button onClick={() => setStep(2)} className="text-xs font-bold text-[#64748B] hover:text-[#10D8D8]">
                Geri
              </button>
            </div>
          </div>

          <div className="text-xs font-bold text-slate-400 pb-1">
            Seçilen Tarih: {selectedDate}
          </div>

          {loadingSlots ? (
            <div className="flex flex-col items-center justify-center py-12 gap-3">
              <div className="w-8 h-8 border-4 border-[#10D8D8] border-t-transparent rounded-full animate-spin" />
              <span className="text-xs text-[#64748B]">Müsait saatler kontrol ediliyor...</span>
            </div>
          ) : slots.length > 0 ? (
            <div className="grid grid-cols-2 gap-3 max-h-[300px] overflow-y-auto pr-1">
              {slots.map((slot) => {
                const isFull = slot.slots_left === 0;
                const isBlocked = slot.has_pending;
                
                let label = `${slot.slots_left} yer müsait`;
                let subtext = "";
                
                if (isFull) {
                  label = "Dolu";
                  if (slot.confirmed_names.length > 0) {
                    subtext = slot.confirmed_names.join(", ");
                  }
                } else if (isBlocked) {
                  label = "Geçici ayrıldı";
                }

                const isDisabled = isFull || isBlocked;

                return (
                  <button
                    key={slot.time}
                    disabled={isDisabled}
                    onClick={() => {
                      setSelectedSlot(slot);
                      setStep(4);
                    }}
                    className={`p-3 border rounded-xl flex flex-col items-center justify-center gap-1.5 transition-all text-center ${
                      isDisabled
                        ? "bg-slate-100 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-400 cursor-not-allowed opacity-60"
                        : "border-[#D0E4E8] dark:border-[#243141] hover:border-[#10D8D8] bg-slate-50/50 dark:bg-slate-900/30"
                    }`}
                  >
                    <span className="font-extrabold text-sm">{slot.time}</span>
                    <span className="text-[10px] font-semibold">{label}</span>
                    {subtext && (
                      <span className="text-[9px] text-[#64748B] dark:text-[#94A3B8] font-medium max-w-full truncate">
                        {subtext}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-10 text-sm text-[#64748B] dark:text-[#94A3B8]">
              Bu tarihte uygun saat bulunmamaktadır. İşletme kapalı olabilir veya tüm kapasite dolmuş olabilir.
            </div>
          )}
        </div>
      )}

      {/* STEP 4: Customer Details Form */}
      {step === 4 && selectedService && selectedDate && selectedSlot && (
        <form onSubmit={handleSubmit} className="card space-y-4 bg-white dark:bg-[#131A22]">
          <div className="flex items-center justify-between">
            <h2 className="text-base font-extrabold">Son Adım: İletişim Bilgileri</h2>
            <button type="button" onClick={() => setStep(3)} className="text-xs font-bold text-[#64748B] hover:text-[#10D8D8]">
              Geri
            </button>
          </div>

          <div className="bg-slate-50 dark:bg-slate-900/50 p-3.5 rounded-xl border border-slate-100 dark:border-slate-800 text-xs font-medium space-y-1.5 text-[#475569] dark:text-[#CBD5E1]">
            <div><span className="font-extrabold text-[#64748B]">Seçilen Hizmet:</span> {selectedService.title} ({selectedService.durationMinutes || 30} dk)</div>
            <div><span className="font-extrabold text-[#64748B]">Tarih ve Saat:</span> {selectedDate} · {selectedSlot.time}</div>
            {selectedService.price && <div><span className="font-extrabold text-[#64748B]">Hizmet Bedeli:</span> {selectedService.price}</div>}
          </div>

          <div className="space-y-4 pt-2">
            <div>
              <label htmlFor="customer-name" className="label-text">Ad Soyad</label>
              <input
                id="customer-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Örn: Ahmet Yılmaz"
                className="input-field"
                required
              />
            </div>

            <div>
              <label htmlFor="customer-phone" className="label-text">Telefon Numarası</label>
              <input
                id="customer-phone"
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="Örn: 0555 123 4567"
                className="input-field"
                required
              />
            </div>

            <div>
              <label htmlFor="customer-notes" className="label-text">Notlar (İsteğe bağlı)</label>
              <textarea
                id="customer-notes"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="İşletmeye iletmek istediğiniz özel bir not veya istek varsa yazın..."
                className="input-field min-h-[80px]"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="btn-primary w-full py-3.5 rounded-xl font-bold mt-2 flex items-center justify-center gap-2"
          >
            {isSubmitting ? (
              <>
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Talep Gönderiliyor...
              </>
            ) : (
              "Randevu Talebini Onayla"
            )}
          </button>
        </form>
      )}
    </div>
  );
}
