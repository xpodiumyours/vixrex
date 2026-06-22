"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

interface RescheduleRequest {
  id: string;
  requested_time: string;
  status: string;
}

interface Appointment {
  id: string;
  store_slug: string;
  store_name: string;
  customer_name: string;
  customer_phone: string;
  customer_notes?: string;
  service_title: string;
  service_price?: string;
  service_duration: number;
  appointment_time: string;
  status: string;
  created_at: string;
  expires_at: string;
  reschedule_request?: RescheduleRequest | null;
}

interface Slot {
  time: string;
  capacity_total: number;
  capacity_used: number;
  slots_left: number;
  confirmed_names: string[];
  has_pending: boolean;
}

interface BookingTrackerClientProps {
  initialAppointment: Appointment;
  token: string;
}

export default function BookingTrackerClient({ initialAppointment, token }: BookingTrackerClientProps) {
  const [appointment, setAppointment] = useState<Appointment>(initialAppointment);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  // Cancel action state
  const [isCancelling, setIsCancelling] = useState(false);

  // Reschedule state
  const [showRescheduleForm, setShowRescheduleForm] = useState(false);
  const [selectedDate, setSelectedDate] = useState("");
  const [slots, setSlots] = useState<Slot[]>([]);
  const [loadingSlots, setLoadingSlots] = useState(false);
  const [selectedSlot, setSelectedSlot] = useState<Slot | null>(null);
  const [isRescheduling, setIsRescheduling] = useState(false);

  // Fetch updated appointment info
  const fetchLatestInfo = useCallback(async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.rpc("get_appointment_by_token", {
        p_token: token,
      });
      if (error) throw error;
      if (data) setAppointment(data);
    } catch (err) {
      console.error("Error updating appointment data:", err);
    } finally {
      setLoading(false);
    }
  }, [token]);

  // Load slots when reschedule date is selected
  useEffect(() => {
    if (!selectedDate) return;

    async function fetchSlots() {
      setLoadingSlots(true);
      setErrorMessage("");
      try {
        const { data, error } = await supabase.rpc("get_public_booking_slots", {
          p_store_slug: appointment.store_slug,
          p_date: selectedDate,
        });

        if (error) throw error;
        const fetchedSlots = Array.isArray(data) 
          ? data 
          : typeof data === "string" 
          ? JSON.parse(data) 
          : [];
        setSlots(fetchedSlots);
      } catch (err: unknown) {
        console.error("Error fetching slots for reschedule:", err);
        setErrorMessage("Müsait saatler yüklenirken bir hata oluştu.");
      } finally {
        setLoadingSlots(false);
      }
    }

    fetchSlots();
  }, [selectedDate, appointment.store_slug]);

  // Cancel booking
  const handleCancel = async () => {
    if (!confirm("Randevunuzu iptal etmek istediğinize emin misiniz?")) return;

    setIsCancelling(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      const { data, error } = await supabase.rpc("cancel_appointment_by_token", {
        p_token: token,
      });

      if (error || !data) throw error || new Error("İptal işlemi gerçekleştirilemedi.");
      
      setSuccessMessage("Randevunuz başarıyla iptal edilmiştir.");
      fetchLatestInfo();
    } catch (err: unknown) {
      console.error("Error cancelling appointment:", err);
      const errMsg = err instanceof Error ? err.message : "İptal işlemi sırasında bir sorun oluştu.";
      setErrorMessage(errMsg);
    } finally {
      setIsCancelling(false);
    }
  };

  // Submit reschedule
  const handleReschedule = async () => {
    if (!selectedDate || !selectedSlot) return;

    setIsRescheduling(true);
    setErrorMessage("");
    setSuccessMessage("");

    try {
      const dateTimeStr = `${selectedDate}T${selectedSlot.time}:00`;
      const { data, error } = await supabase.rpc("request_appointment_reschedule", {
        p_token: token,
        p_new_time: new Date(dateTimeStr).toISOString(),
      });

      if (error || !data) {
        if (error?.message.includes("CAPACITY_FULL")) {
          throw new Error("Seçtiğiniz saatte kapasite doludur, lütfen başka bir saat seçin.");
        }
        throw error || new Error("Tarih değiştirme talebi iletilemedi.");
      }

      setSuccessMessage("Tarih ve saat değiştirme talebi başarıyla işletmeye iletildi.");
      setShowRescheduleForm(false);
      fetchLatestInfo();
    } catch (err: unknown) {
      console.error("Error rescheduling appointment:", err);
      const errMsg = err instanceof Error ? err.message : "Tarih değişikliği talebi gönderilirken bir hata oluştu.";
      setErrorMessage(errMsg);
    } finally {
      setIsRescheduling(false);
    }
  };

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

  // Helper date formatting
  const formatDateTR = (dateStr: string) => {
    try {
      const d = new Date(dateStr);
      return d.toLocaleDateString("tr-TR", { weekday: "long", day: "numeric", month: "long", hour: "2-digit", minute: "2-digit" });
    } catch {
      return dateStr;
    }
  };

  const formatDateLabel = (date: Date) => {
    return date.toLocaleDateString("tr-TR", { weekday: "long", day: "numeric", month: "long" });
  };

  const formatDateISO = (date: Date) => {
    return date.toISOString().split("T")[0];
  };

  // Status mapping
  const getStatusDetails = (status: string) => {
    switch (status) {
      case "pending":
        return {
          title: "Onay Bekliyor",
          desc: "Talebiniz işletmeye iletildi. İşletmenin onayı bekleniyor.",
          colorClass: "bg-amber-500/10 text-amber-600 border-amber-200 dark:border-amber-950",
          iconColor: "text-amber-500",
        };
      case "confirmed":
        return {
          title: "Onaylandı",
          desc: "Randevunuz kesinleşti! Belirtilen tarih ve saatte hazır olmanız rica olunur.",
          colorClass: "bg-emerald-500/10 text-emerald-600 border-emerald-200 dark:border-emerald-950",
          iconColor: "text-emerald-500",
        };
      case "rejected":
        return {
          title: "Kabul Edilmedi",
          desc: "Randevu talebiniz maalesef kabul edilmedi. Farklı bir saate talep oluşturabilirsiniz.",
          colorClass: "bg-red-500/10 text-red-600 border-red-200 dark:border-red-950",
          iconColor: "text-red-500",
        };
      case "cancelled_by_customer":
        return {
          title: "İptal Edildi (Sizin tarafınızdan)",
          desc: "Bu randevu talebini kendi isteğinizle iptal ettiniz.",
          colorClass: "bg-slate-500/10 text-slate-600 border-slate-200 dark:border-slate-800",
          iconColor: "text-slate-500",
        };
      case "cancelled_by_store":
        return {
          title: "İptal Edildi (İşletme)",
          desc: "Bu randevu işletme tarafından iptal edildi. Bilgi almak için işletmeyle iletişime geçebilirsiniz.",
          colorClass: "bg-rose-500/10 text-rose-600 border-rose-200 dark:border-rose-950",
          iconColor: "text-rose-500",
        };
      case "expired":
        return {
          title: "Süresi Doldu",
          desc: "İşletme tarafından zamanında onaylanmayan randevu talebinin süresi dolmuştur.",
          colorClass: "bg-slate-500/10 text-slate-600 border-slate-200 dark:border-slate-800",
          iconColor: "text-slate-500",
        };
      default:
        return {
          title: "Bilinmiyor",
          desc: "Randevu durumu alınamadı.",
          colorClass: "bg-slate-500/10 text-slate-600 border-slate-200",
          iconColor: "text-slate-500",
        };
    }
  };

  const statusInfo = getStatusDetails(appointment.status);
  const showActions = appointment.status === "pending" || appointment.status === "confirmed";

  return (
    <div className="space-y-6">
      {/* Back button and page title */}
      <div className="flex justify-between items-center bg-white dark:bg-[#131A22] border border-[#D0E4E8] dark:border-[#243141] rounded-2xl p-4 shadow-sm">
        <Link href={`/v/${appointment.store_slug}`} className="text-sm font-bold text-[#64748B] hover:text-[#10D8D8] flex items-center gap-1">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6"/></svg>
          {appointment.store_name}
        </Link>
        <button 
          onClick={fetchLatestInfo}
          disabled={loading}
          className="text-xs font-bold text-[#38A0E4] hover:text-[#10D8D8] flex items-center gap-1 disabled:opacity-50"
        >
          {loading ? "Güncelleniyor..." : "Yenile"}
        </button>
      </div>

      {successMessage && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 dark:text-emerald-400 text-xs font-semibold rounded-xl">
          {successMessage}
        </div>
      )}

      {errorMessage && (
        <div className="p-4 bg-red-500/10 border border-red-500/20 text-red-600 dark:text-red-400 text-xs font-semibold rounded-xl">
          {errorMessage}
        </div>
      )}

      {/* Live Status Card */}
      <div className={`card border p-6 space-y-4 rounded-2xl ${statusInfo.colorClass}`}>
        <div className="flex items-center gap-3">
          <div className={`shrink-0 ${statusInfo.iconColor}`}>
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
          </div>
          <h2 className="font-extrabold text-base leading-none">{statusInfo.title}</h2>
        </div>
        <p className="text-xs leading-relaxed">{statusInfo.desc}</p>
      </div>

      {/* Appointment Info Details */}
      <div className="card space-y-4 bg-white dark:bg-[#131A22]">
        <h2 className="text-sm font-extrabold text-[#64748B] dark:text-[#94A3B8] border-b pb-2">Randevu Detayları</h2>
        <div className="space-y-3 text-xs">
          <div className="flex justify-between">
            <span className="font-bold text-[#64748B]">Hizmet</span>
            <span className="font-extrabold">{appointment.service_title} ({appointment.service_duration} dk)</span>
          </div>
          {appointment.service_price && (
            <div className="flex justify-between">
              <span className="font-bold text-[#64748B]">Hizmet Bedeli</span>
              <span className="font-extrabold text-[#38A0E4]">{appointment.service_price}</span>
            </div>
          )}
          <div className="flex justify-between">
            <span className="font-bold text-[#64748B]">Randevu Saati</span>
            <span className="font-extrabold text-slate-800 dark:text-slate-200">{formatDateTR(appointment.appointment_time)}</span>
          </div>
          <div className="flex justify-between">
            <span className="font-bold text-[#64748B]">Müşteri</span>
            <span className="font-bold">{appointment.customer_name}</span>
          </div>
          <div className="flex justify-between">
            <span className="font-bold text-[#64748B]">Telefon</span>
            <span className="font-bold">{appointment.customer_phone}</span>
          </div>
          {appointment.customer_notes && (
            <div className="pt-2 border-t text-left">
              <span className="font-bold text-[#64748B] block mb-1">Müşteri Notu:</span>
              <p className="text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-slate-900/50 p-2.5 rounded-lg border leading-relaxed">
                {appointment.customer_notes}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Pending Reschedule Alert */}
      {appointment.reschedule_request && appointment.reschedule_request.status === "pending" && (
        <div className="p-4 bg-amber-500/10 border border-amber-500/20 text-amber-700 dark:text-amber-400 text-xs font-semibold rounded-xl space-y-1">
          <div className="font-extrabold">Tarih Değiştirme Talebi Gönderildi</div>
          <div className="text-[11px] font-normal leading-relaxed">
            İşletmenin şu yeni randevu saatini onaylaması bekleniyor: 
            <strong className="block mt-1 font-bold text-slate-800 dark:text-slate-200">{formatDateTR(appointment.reschedule_request.requested_time)}</strong>
          </div>
        </div>
      )}

      {/* Action Buttons */}
      {showActions && !showRescheduleForm && (
        <div className="flex flex-col gap-2 pt-2">
          <button 
            onClick={() => setShowRescheduleForm(true)}
            className="btn-secondary w-full py-3 rounded-xl font-bold text-sm"
          >
            Tarih ve Saati Değiştir
          </button>
          
          <button
            onClick={handleCancel}
            disabled={isCancelling}
            className="w-full py-3 bg-red-500/10 hover:bg-red-500/20 text-red-600 font-bold text-sm rounded-xl transition-all flex items-center justify-center gap-2 border border-red-200 dark:border-red-950"
          >
            {isCancelling ? "İptal Ediliyor..." : "Randevuyu İptal Et"}
          </button>
        </div>
      )}

      {/* Reschedule UI form */}
      {showRescheduleForm && (
        <div className="card space-y-4 bg-white dark:bg-[#131A22] animate-fade-in border-[#38A0E4]/30">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-extrabold">Yeni Randevu Saati Seçin</h2>
            <button 
              onClick={() => {
                setShowRescheduleForm(false);
                setSelectedDate("");
                setSelectedSlot(null);
              }}
              className="text-xs font-bold text-[#64748B] hover:text-red-500"
            >
              Vazgeç
            </button>
          </div>

          {/* Date Picker */}
          {!selectedDate ? (
            <div className="space-y-2">
              <span className="label-text">Yeni Tarih Seçin</span>
              <div className="max-h-[200px] overflow-y-auto space-y-1.5 pr-1">
                {datesList.map((date) => {
                  const dateStr = formatDateLabel(date);
                  const dateVal = formatDateISO(date);
                  return (
                    <button
                      key={dateVal}
                      onClick={() => setSelectedDate(dateVal)}
                      className="w-full text-left p-2.5 border border-[#D0E4E8] dark:border-[#243141] hover:border-[#10D8D8] rounded-xl text-xs font-bold bg-slate-50/50 dark:bg-slate-900/30"
                    >
                      {dateStr}
                    </button>
                  );
                })}
              </div>
            </div>
          ) : (
            // Slot Picker
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-xs font-bold text-[#64748B]">Tarih: {selectedDate}</span>
                <button 
                  type="button" 
                  onClick={() => {
                    setSelectedDate("");
                    setSelectedSlot(null);
                  }}
                  className="text-[10px] text-[#38A0E4] font-extrabold hover:underline"
                >
                  Tarihi Değiştir
                </button>
              </div>

              {loadingSlots ? (
                <div className="flex justify-center py-6">
                  <div className="w-6 h-6 border-2 border-[#10D8D8] border-t-transparent rounded-full animate-spin" />
                </div>
              ) : slots.length > 0 ? (
                <div className="grid grid-cols-3 gap-2 max-h-[180px] overflow-y-auto pr-1">
                  {slots.map((slot) => {
                    const isFull = slot.slots_left === 0;
                    const isBlocked = slot.has_pending;
                    const isDisabled = isFull || isBlocked;
                    const isSelected = selectedSlot?.time === slot.time;

                    return (
                      <button
                        key={slot.time}
                        disabled={isDisabled}
                        type="button"
                        onClick={() => setSelectedSlot(slot)}
                        className={`p-2.5 border text-xs font-bold rounded-xl transition-all ${
                          isDisabled 
                            ? "bg-slate-100 dark:bg-slate-900 border-slate-200 dark:border-slate-800 text-slate-300 opacity-60 cursor-not-allowed"
                            : isSelected
                            ? "border-[#10D8D8] bg-[#10D8D8]/10 text-[#0EA8B0]"
                            : "border-[#D0E4E8] dark:border-[#243141] hover:border-[#10D8D8] bg-slate-50/50 dark:bg-slate-900/30"
                        }`}
                      >
                        {slot.time}
                      </button>
                    );
                  })}
                </div>
              ) : (
                <p className="text-xs text-slate-400 text-center py-4">Bu tarihte müsait saat bulunmamaktadır.</p>
              )}

              {selectedSlot && (
                <button
                  onClick={handleReschedule}
                  disabled={isRescheduling}
                  className="btn-primary w-full py-3 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5"
                >
                  {isRescheduling ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      Gönderiliyor...
                    </>
                  ) : (
                    `Değişikliği Gönder (${selectedDate} - ${selectedSlot.time})`
                  )}
                </button>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
