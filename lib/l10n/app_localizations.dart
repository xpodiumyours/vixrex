import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'VixRex'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In tr, this message translates to:
  /// **'Uyarı'**
  String get warning;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get next;

  /// No description provided for @done.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In tr, this message translates to:
  /// **'Sırala'**
  String get sort;

  /// No description provided for @selectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Seç'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Kaldır'**
  String get deselectAll;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResults;

  /// No description provided for @networkError.
  ///
  /// In tr, this message translates to:
  /// **'Ağ hatası. İnternet bağlantınızı kontrol edin.'**
  String get networkError;

  /// No description provided for @unknownError.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get unknownError;

  /// No description provided for @authError.
  ///
  /// In tr, this message translates to:
  /// **'Giriş bilgileri hatalı. Lütfen tekrar deneyin.'**
  String get authError;

  /// No description provided for @permissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkiniz yok.'**
  String get permissionDenied;

  /// No description provided for @notFound.
  ///
  /// In tr, this message translates to:
  /// **'İstenen kaynak bulunamadı.'**
  String get notFound;

  /// No description provided for @timeout.
  ///
  /// In tr, this message translates to:
  /// **'İşlem zaman aşımına uğradı.'**
  String get timeout;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @name.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get name;

  /// No description provided for @surname.
  ///
  /// In tr, this message translates to:
  /// **'Soyisim'**
  String get surname;

  /// No description provided for @address.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get address;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// No description provided for @district.
  ///
  /// In tr, this message translates to:
  /// **'İlçe'**
  String get district;

  /// No description provided for @saveChanges.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikleri Kaydet'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikleri Sil'**
  String get discardChanges;

  /// No description provided for @areYouSure.
  ///
  /// In tr, this message translates to:
  /// **'Emin misiniz?'**
  String get areYouSure;

  /// No description provided for @deleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu kaydı silmek istediğinizden emin misiniz?'**
  String get deleteConfirm;

  /// No description provided for @undo.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get undo;

  /// No description provided for @copied.
  ///
  /// In tr, this message translates to:
  /// **'Panoya kopyalandı'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In tr, this message translates to:
  /// **'Yapıştır'**
  String get paste;

  /// No description provided for @cut.
  ///
  /// In tr, this message translates to:
  /// **'Kes'**
  String get cut;

  /// No description provided for @selectAllText.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Seç'**
  String get selectAllText;

  /// No description provided for @undoAction.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get undoAction;

  /// No description provided for @redoAction.
  ///
  /// In tr, this message translates to:
  /// **'Yinele'**
  String get redoAction;

  /// No description provided for @bold.
  ///
  /// In tr, this message translates to:
  /// **'Kalın'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In tr, this message translates to:
  /// **'İtalik'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In tr, this message translates to:
  /// **'Altı Çizili'**
  String get underline;

  /// No description provided for @bulletList.
  ///
  /// In tr, this message translates to:
  /// **'Madde İşaretli Liste'**
  String get bulletList;

  /// No description provided for @numberedList.
  ///
  /// In tr, this message translates to:
  /// **'Numaralı Liste'**
  String get numberedList;

  /// No description provided for @heading.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get heading;

  /// No description provided for @quote.
  ///
  /// In tr, this message translates to:
  /// **'Alıntı'**
  String get quote;

  /// No description provided for @code.
  ///
  /// In tr, this message translates to:
  /// **'Kod'**
  String get code;

  /// No description provided for @link.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get link;

  /// No description provided for @image.
  ///
  /// In tr, this message translates to:
  /// **'Görsel'**
  String get image;

  /// No description provided for @video.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @document.
  ///
  /// In tr, this message translates to:
  /// **'Belge'**
  String get document;

  /// No description provided for @file.
  ///
  /// In tr, this message translates to:
  /// **'Dosya'**
  String get file;

  /// No description provided for @upload.
  ///
  /// In tr, this message translates to:
  /// **'Yükle'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In tr, this message translates to:
  /// **'İndir'**
  String get download;

  /// No description provided for @export.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar'**
  String get export;

  /// No description provided for @import.
  ///
  /// In tr, this message translates to:
  /// **'İçe Aktar'**
  String get import;

  /// No description provided for @print.
  ///
  /// In tr, this message translates to:
  /// **'Yazdır'**
  String get print;

  /// No description provided for @preview.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get preview;

  /// No description provided for @fullscreen.
  ///
  /// In tr, this message translates to:
  /// **'Tam Ekran'**
  String get fullscreen;

  /// No description provided for @zoomIn.
  ///
  /// In tr, this message translates to:
  /// **'Yakınlaştır'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In tr, this message translates to:
  /// **'Uzaklaştır'**
  String get zoomOut;

  /// No description provided for @fitToScreen.
  ///
  /// In tr, this message translates to:
  /// **'Ekrana Sığdır'**
  String get fitToScreen;

  /// No description provided for @rotateLeft.
  ///
  /// In tr, this message translates to:
  /// **'Sola Döndür'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In tr, this message translates to:
  /// **'Sağa Döndür'**
  String get rotateRight;

  /// No description provided for @flipHorizontal.
  ///
  /// In tr, this message translates to:
  /// **'Yatay Çevir'**
  String get flipHorizontal;

  /// No description provided for @flipVertical.
  ///
  /// In tr, this message translates to:
  /// **'Dikey Çevir'**
  String get flipVertical;

  /// No description provided for @crop.
  ///
  /// In tr, this message translates to:
  /// **'Kırp'**
  String get crop;

  /// No description provided for @resize.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Boyutlandır'**
  String get resize;

  /// No description provided for @brightness.
  ///
  /// In tr, this message translates to:
  /// **'Parlaklık'**
  String get brightness;

  /// No description provided for @contrast.
  ///
  /// In tr, this message translates to:
  /// **'Kontrast'**
  String get contrast;

  /// No description provided for @saturation.
  ///
  /// In tr, this message translates to:
  /// **'Doygunluk'**
  String get saturation;

  /// No description provided for @blur.
  ///
  /// In tr, this message translates to:
  /// **'Bulanıklık'**
  String get blur;

  /// No description provided for @sharpness.
  ///
  /// In tr, this message translates to:
  /// **'Keskinlik'**
  String get sharpness;

  /// No description provided for @original.
  ///
  /// In tr, this message translates to:
  /// **'Orijinal'**
  String get original;

  /// No description provided for @apply.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @undoFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtreyi Geri Al'**
  String get undoFilter;

  /// No description provided for @saveAs.
  ///
  /// In tr, this message translates to:
  /// **'Farklı Kaydet'**
  String get saveAs;

  /// No description provided for @overwrite.
  ///
  /// In tr, this message translates to:
  /// **'Üzerine Yaz'**
  String get overwrite;

  /// No description provided for @replace.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get replace;

  /// No description provided for @merge.
  ///
  /// In tr, this message translates to:
  /// **'Birleştir'**
  String get merge;

  /// No description provided for @split.
  ///
  /// In tr, this message translates to:
  /// **'Ayır'**
  String get split;

  /// No description provided for @duplicate.
  ///
  /// In tr, this message translates to:
  /// **'Çoğalt'**
  String get duplicate;

  /// No description provided for @copyTo.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copyTo;

  /// No description provided for @moveTo.
  ///
  /// In tr, this message translates to:
  /// **'Taşı'**
  String get moveTo;

  /// No description provided for @rename.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden Adlandır'**
  String get rename;

  /// No description provided for @details.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get details;

  /// No description provided for @summary.
  ///
  /// In tr, this message translates to:
  /// **'Özet'**
  String get summary;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @tags.
  ///
  /// In tr, this message translates to:
  /// **'Etiketler'**
  String get tags;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// No description provided for @price.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get quantity;

  /// No description provided for @total.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In tr, this message translates to:
  /// **'Ara Toplam'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In tr, this message translates to:
  /// **'İndirim'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In tr, this message translates to:
  /// **'Vergi'**
  String get tax;

  /// No description provided for @shipping.
  ///
  /// In tr, this message translates to:
  /// **'Kargo'**
  String get shipping;

  /// No description provided for @payment.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme'**
  String get payment;

  /// No description provided for @order.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş'**
  String get order;

  /// No description provided for @orders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler'**
  String get orders;

  /// No description provided for @customer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get customer;

  /// No description provided for @customers.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler'**
  String get customers;

  /// No description provided for @product.
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get product;

  /// No description provided for @products.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get products;

  /// No description provided for @inventory.
  ///
  /// In tr, this message translates to:
  /// **'Stok'**
  String get inventory;

  /// No description provided for @stock.
  ///
  /// In tr, this message translates to:
  /// **'Stok'**
  String get stock;

  /// No description provided for @inStock.
  ///
  /// In tr, this message translates to:
  /// **'Stokta Var'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In tr, this message translates to:
  /// **'Stokta Yok'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In tr, this message translates to:
  /// **'Stok Azalıyor'**
  String get lowStock;

  /// No description provided for @barcode.
  ///
  /// In tr, this message translates to:
  /// **'Barkod'**
  String get barcode;

  /// No description provided for @sku.
  ///
  /// In tr, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @supplier.
  ///
  /// In tr, this message translates to:
  /// **'Tedarikçi'**
  String get supplier;

  /// No description provided for @supplierPrice.
  ///
  /// In tr, this message translates to:
  /// **'Tedarikçi Fiyatı'**
  String get supplierPrice;

  /// No description provided for @salePrice.
  ///
  /// In tr, this message translates to:
  /// **'Satış Fiyatı'**
  String get salePrice;

  /// No description provided for @costPrice.
  ///
  /// In tr, this message translates to:
  /// **'Maliyet Fiyatı'**
  String get costPrice;

  /// No description provided for @profit.
  ///
  /// In tr, this message translates to:
  /// **'Kâr'**
  String get profit;

  /// No description provided for @margin.
  ///
  /// In tr, this message translates to:
  /// **'Marj'**
  String get margin;

  /// No description provided for @revenue.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get revenue;

  /// No description provided for @expenses.
  ///
  /// In tr, this message translates to:
  /// **'Giderler'**
  String get expenses;

  /// No description provided for @loss.
  ///
  /// In tr, this message translates to:
  /// **'Zarar'**
  String get loss;

  /// No description provided for @breakEven.
  ///
  /// In tr, this message translates to:
  /// **'Başabaş Noktası'**
  String get breakEven;

  /// No description provided for @roi.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım Getirisi'**
  String get roi;

  /// No description provided for @conversionRate.
  ///
  /// In tr, this message translates to:
  /// **'Dönüşüm Oranı'**
  String get conversionRate;

  /// No description provided for @visitors.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretçiler'**
  String get visitors;

  /// No description provided for @pageViews.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa Görüntüleme'**
  String get pageViews;

  /// No description provided for @bounceRate.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Çıkma Oranı'**
  String get bounceRate;

  /// No description provided for @sessionDuration.
  ///
  /// In tr, this message translates to:
  /// **'Oturum Süresi'**
  String get sessionDuration;

  /// No description provided for @newUsers.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kullanıcılar'**
  String get newUsers;

  /// No description provided for @returningUsers.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dönen Kullanıcılar'**
  String get returningUsers;

  /// No description provided for @trafficSources.
  ///
  /// In tr, this message translates to:
  /// **'Trafik Kaynakları'**
  String get trafficSources;

  /// No description provided for @topPages.
  ///
  /// In tr, this message translates to:
  /// **'En Çok Ziyaret Edilen Sayfalar'**
  String get topPages;

  /// No description provided for @geography.
  ///
  /// In tr, this message translates to:
  /// **'Coğrafya'**
  String get geography;

  /// No description provided for @devices.
  ///
  /// In tr, this message translates to:
  /// **'Cihazlar'**
  String get devices;

  /// No description provided for @browsers.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcılar'**
  String get browsers;

  /// No description provided for @operatingSystems.
  ///
  /// In tr, this message translates to:
  /// **'İşletim Sistemleri'**
  String get operatingSystems;

  /// No description provided for @socialMedia.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya'**
  String get socialMedia;

  /// No description provided for @analytics.
  ///
  /// In tr, this message translates to:
  /// **'Analitik'**
  String get analytics;

  /// No description provided for @reports.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get reports;

  /// No description provided for @dashboard.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol Paneli'**
  String get dashboard;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @messages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get messages;

  /// No description provided for @chat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get chat;

  /// No description provided for @support.
  ///
  /// In tr, this message translates to:
  /// **'Destek'**
  String get support;

  /// No description provided for @help.
  ///
  /// In tr, this message translates to:
  /// **'Yardım'**
  String get help;

  /// No description provided for @faq.
  ///
  /// In tr, this message translates to:
  /// **'Sıkça Sorulan Sorular'**
  String get faq;

  /// No description provided for @terms.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Şartları'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacy;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @contact.
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get contact;

  /// No description provided for @blog.
  ///
  /// In tr, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @news.
  ///
  /// In tr, this message translates to:
  /// **'Haberler'**
  String get news;

  /// No description provided for @updates.
  ///
  /// In tr, this message translates to:
  /// **'Güncellemeler'**
  String get updates;

  /// No description provided for @announcements.
  ///
  /// In tr, this message translates to:
  /// **'Duyurular'**
  String get announcements;

  /// No description provided for @events.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get events;

  /// No description provided for @calendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendar;

  /// No description provided for @schedule.
  ///
  /// In tr, this message translates to:
  /// **'Program'**
  String get schedule;

  /// No description provided for @appointments.
  ///
  /// In tr, this message translates to:
  /// **'Randevular'**
  String get appointments;

  /// No description provided for @bookings.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyonlar'**
  String get bookings;

  /// No description provided for @reservations.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyonlar'**
  String get reservations;

  /// No description provided for @availability.
  ///
  /// In tr, this message translates to:
  /// **'Müsaitlik'**
  String get availability;

  /// No description provided for @timeSlots.
  ///
  /// In tr, this message translates to:
  /// **'Saat Dilimleri'**
  String get timeSlots;

  /// No description provided for @duration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get duration;

  /// No description provided for @startTime.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Saati'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Saati'**
  String get endTime;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @time.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get time;

  /// No description provided for @day.
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get day;

  /// No description provided for @week.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get week;

  /// No description provided for @month.
  ///
  /// In tr, this message translates to:
  /// **'Ay'**
  String get month;

  /// No description provided for @year.
  ///
  /// In tr, this message translates to:
  /// **'Yıl'**
  String get year;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu Hafta'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In tr, this message translates to:
  /// **'Geçen Hafta'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bu Ay'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In tr, this message translates to:
  /// **'Geçen Ay'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In tr, this message translates to:
  /// **'Bu Yıl'**
  String get thisYear;

  /// No description provided for @lastYear.
  ///
  /// In tr, this message translates to:
  /// **'Geçen Yıl'**
  String get lastYear;

  /// No description provided for @allTime.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Zamanlar'**
  String get allTime;

  /// No description provided for @custom.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get custom;

  /// No description provided for @from.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get from;

  /// No description provided for @to.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get to;

  /// No description provided for @applyFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtreyi Uygula'**
  String get applyFilter;

  /// No description provided for @clearFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtreyi Temizle'**
  String get clearFilter;

  /// No description provided for @noFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtre Yok'**
  String get noFilter;

  /// No description provided for @sortAscending.
  ///
  /// In tr, this message translates to:
  /// **'Artan Sıralama'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In tr, this message translates to:
  /// **'Azalan Sıralama'**
  String get sortDescending;

  /// No description provided for @groupBy.
  ///
  /// In tr, this message translates to:
  /// **'Grupla'**
  String get groupBy;

  /// No description provided for @columns.
  ///
  /// In tr, this message translates to:
  /// **'Sütunlar'**
  String get columns;

  /// No description provided for @rows.
  ///
  /// In tr, this message translates to:
  /// **'Satırlar'**
  String get rows;

  /// No description provided for @cells.
  ///
  /// In tr, this message translates to:
  /// **'Hücreler'**
  String get cells;

  /// No description provided for @table.
  ///
  /// In tr, this message translates to:
  /// **'Tablo'**
  String get table;

  /// No description provided for @list.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get list;

  /// No description provided for @grid.
  ///
  /// In tr, this message translates to:
  /// **'Izgara'**
  String get grid;

  /// No description provided for @card.
  ///
  /// In tr, this message translates to:
  /// **'Kart'**
  String get card;

  /// No description provided for @compact.
  ///
  /// In tr, this message translates to:
  /// **'Kompakt'**
  String get compact;

  /// No description provided for @comfortable.
  ///
  /// In tr, this message translates to:
  /// **'Rahat'**
  String get comfortable;

  /// No description provided for @spacious.
  ///
  /// In tr, this message translates to:
  /// **'Geniş'**
  String get spacious;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In tr, this message translates to:
  /// **'Karanlık Mod'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In tr, this message translates to:
  /// **'Aydınlık Mod'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Modu'**
  String get systemMode;

  /// No description provided for @fontSize.
  ///
  /// In tr, this message translates to:
  /// **'Yazı Tipi Boyutu'**
  String get fontSize;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @region.
  ///
  /// In tr, this message translates to:
  /// **'Bölge'**
  String get region;

  /// No description provided for @timezone.
  ///
  /// In tr, this message translates to:
  /// **'Saat Dilimi'**
  String get timezone;

  /// No description provided for @currency.
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get currency;

  /// No description provided for @dateFormat.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Formatı'**
  String get dateFormat;

  /// No description provided for @timeFormat.
  ///
  /// In tr, this message translates to:
  /// **'Saat Formatı'**
  String get timeFormat;

  /// No description provided for @numberFormat.
  ///
  /// In tr, this message translates to:
  /// **'Sayı Formatı'**
  String get numberFormat;

  /// No description provided for @emailNotifications.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Bildirimleri'**
  String get emailNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Anlık Bildirimler'**
  String get pushNotifications;

  /// No description provided for @smsNotifications.
  ///
  /// In tr, this message translates to:
  /// **'SMS Bildirimleri'**
  String get smsNotifications;

  /// No description provided for @marketingEmails.
  ///
  /// In tr, this message translates to:
  /// **'Pazarlama E-postaları'**
  String get marketingEmails;

  /// No description provided for @securityAlerts.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Uyarıları'**
  String get securityAlerts;

  /// No description provided for @accountUpdates.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Güncellemeleri'**
  String get accountUpdates;

  /// No description provided for @orderUpdates.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Güncellemeleri'**
  String get orderUpdates;

  /// No description provided for @appointmentReminders.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Hatırlatmalari'**
  String get appointmentReminders;

  /// No description provided for @newsletter.
  ///
  /// In tr, this message translates to:
  /// **'Bülten'**
  String get newsletter;

  /// No description provided for @subscribe.
  ///
  /// In tr, this message translates to:
  /// **'Abone Ol'**
  String get subscribe;

  /// No description provided for @unsubscribe.
  ///
  /// In tr, this message translates to:
  /// **'Abonelikten Çık'**
  String get unsubscribe;

  /// No description provided for @follow.
  ///
  /// In tr, this message translates to:
  /// **'Takip Et'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In tr, this message translates to:
  /// **'Takipten Çık'**
  String get unfollow;

  /// No description provided for @like.
  ///
  /// In tr, this message translates to:
  /// **'Beğen'**
  String get like;

  /// No description provided for @unlike.
  ///
  /// In tr, this message translates to:
  /// **'Beğenmekten Vazgeç'**
  String get unlike;

  /// No description provided for @comment.
  ///
  /// In tr, this message translates to:
  /// **'Yorum Yap'**
  String get comment;

  /// No description provided for @reply.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtla'**
  String get reply;

  /// No description provided for @report.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet Et'**
  String get report;

  /// No description provided for @block.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In tr, this message translates to:
  /// **'Engeli Kaldır'**
  String get unblock;

  /// No description provided for @mute.
  ///
  /// In tr, this message translates to:
  /// **'Sessize Al'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In tr, this message translates to:
  /// **'Sessizliği Kaldır'**
  String get unmute;

  /// No description provided for @pin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitle'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlemeyi Kaldır'**
  String get unpin;

  /// No description provided for @archive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivden Çıkar'**
  String get unarchive;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get restore;

  /// No description provided for @permanentDelete.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı Olarak Sil'**
  String get permanentDelete;

  /// No description provided for @confirmDelete.
  ///
  /// In tr, this message translates to:
  /// **'Silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'**
  String get confirmDelete;

  /// No description provided for @cancelBooking.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu İptal Et'**
  String get cancelBooking;

  /// No description provided for @confirmBooking.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Onayla'**
  String get confirmBooking;

  /// No description provided for @rejectBooking.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Reddet'**
  String get rejectBooking;

  /// No description provided for @completeBooking.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Tamamla'**
  String get completeBooking;

  /// No description provided for @rescheduleBooking.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Yeniden Planla'**
  String get rescheduleBooking;

  /// No description provided for @pending.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get confirmed;

  /// No description provided for @rejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get rejected;

  /// No description provided for @cancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get cancelled;

  /// No description provided for @completed.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get completed;

  /// No description provided for @active.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get inactive;

  /// No description provided for @draft.
  ///
  /// In tr, this message translates to:
  /// **'Taslak'**
  String get draft;

  /// No description provided for @published.
  ///
  /// In tr, this message translates to:
  /// **'Yayınlandı'**
  String get published;

  /// No description provided for @archived.
  ///
  /// In tr, this message translates to:
  /// **'Arşivlendi'**
  String get archived;

  /// No description provided for @featured.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkan'**
  String get featured;

  /// No description provided for @popular.
  ///
  /// In tr, this message translates to:
  /// **'Popüler'**
  String get popular;

  /// No description provided for @trending.
  ///
  /// In tr, this message translates to:
  /// **'Gündemde'**
  String get trending;

  /// No description provided for @newLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get newLabel;

  /// No description provided for @updated.
  ///
  /// In tr, this message translates to:
  /// **'Güncellendi'**
  String get updated;

  /// No description provided for @deleted.
  ///
  /// In tr, this message translates to:
  /// **'Silindi'**
  String get deleted;

  /// No description provided for @created.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturuldu'**
  String get created;

  /// No description provided for @modified.
  ///
  /// In tr, this message translates to:
  /// **'Değiştirildi'**
  String get modified;

  /// No description provided for @lastModified.
  ///
  /// In tr, this message translates to:
  /// **'Son Değişiklik'**
  String get lastModified;

  /// No description provided for @lastUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son Güncelleme'**
  String get lastUpdated;

  /// No description provided for @createdAt.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma Tarihi'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In tr, this message translates to:
  /// **'Güncellenme Tarihi'**
  String get updatedAt;

  /// No description provided for @expiresAt.
  ///
  /// In tr, this message translates to:
  /// **'Son Kullanma Tarihi'**
  String get expiresAt;

  /// No description provided for @startDate.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Tarihi'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Tarihi'**
  String get endDate;

  /// No description provided for @remaining.
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get remaining;

  /// No description provided for @elapsed.
  ///
  /// In tr, this message translates to:
  /// **'Geçen'**
  String get elapsed;

  /// No description provided for @progress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get progress;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get high;

  /// No description provided for @urgent.
  ///
  /// In tr, this message translates to:
  /// **'Acil'**
  String get urgent;

  /// No description provided for @assignedTo.
  ///
  /// In tr, this message translates to:
  /// **'Atanan'**
  String get assignedTo;

  /// No description provided for @createdBy.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturan'**
  String get createdBy;

  /// No description provided for @updatedBy.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleyen'**
  String get updatedBy;

  /// No description provided for @owner.
  ///
  /// In tr, this message translates to:
  /// **'Sahibi'**
  String get owner;

  /// No description provided for @admin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get admin;

  /// No description provided for @user.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get user;

  /// No description provided for @guest.
  ///
  /// In tr, this message translates to:
  /// **'Misafir'**
  String get guest;

  /// No description provided for @member.
  ///
  /// In tr, this message translates to:
  /// **'Üye'**
  String get member;

  /// No description provided for @visitor.
  ///
  /// In tr, this message translates to:
  /// **'Ziyaretçi'**
  String get visitor;

  /// No description provided for @vendor.
  ///
  /// In tr, this message translates to:
  /// **'Satıcı'**
  String get vendor;

  /// No description provided for @partner.
  ///
  /// In tr, this message translates to:
  /// **'Ortak'**
  String get partner;

  /// No description provided for @employee.
  ///
  /// In tr, this message translates to:
  /// **'Çalışan'**
  String get employee;

  /// No description provided for @contractor.
  ///
  /// In tr, this message translates to:
  /// **'Müteahhit'**
  String get contractor;

  /// No description provided for @freelancer.
  ///
  /// In tr, this message translates to:
  /// **'Serbest Çalışan'**
  String get freelancer;

  /// No description provided for @volunteer.
  ///
  /// In tr, this message translates to:
  /// **'Gönüllü'**
  String get volunteer;

  /// No description provided for @donor.
  ///
  /// In tr, this message translates to:
  /// **'Bağışçı'**
  String get donor;

  /// No description provided for @sponsor.
  ///
  /// In tr, this message translates to:
  /// **'Sponsor'**
  String get sponsor;

  /// No description provided for @investor.
  ///
  /// In tr, this message translates to:
  /// **'Yatırımcı'**
  String get investor;

  /// No description provided for @advisor.
  ///
  /// In tr, this message translates to:
  /// **'Danışman'**
  String get advisor;

  /// No description provided for @mentor.
  ///
  /// In tr, this message translates to:
  /// **'Mentor'**
  String get mentor;

  /// No description provided for @coach.
  ///
  /// In tr, this message translates to:
  /// **'Koç'**
  String get coach;

  /// No description provided for @trainer.
  ///
  /// In tr, this message translates to:
  /// **'Eğitmen'**
  String get trainer;

  /// No description provided for @teacher.
  ///
  /// In tr, this message translates to:
  /// **'Öğretmen'**
  String get teacher;

  /// No description provided for @student.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenci'**
  String get student;

  /// No description provided for @alumni.
  ///
  /// In tr, this message translates to:
  /// **'Mezun'**
  String get alumni;

  /// No description provided for @graduate.
  ///
  /// In tr, this message translates to:
  /// **'Mezun'**
  String get graduate;

  /// No description provided for @undergraduate.
  ///
  /// In tr, this message translates to:
  /// **'Lisans Öğrencisi'**
  String get undergraduate;

  /// No description provided for @postgraduate.
  ///
  /// In tr, this message translates to:
  /// **'Lisans Üstü Öğrenci'**
  String get postgraduate;

  /// No description provided for @phd.
  ///
  /// In tr, this message translates to:
  /// **'Doktora Öğrencisi'**
  String get phd;

  /// No description provided for @professor.
  ///
  /// In tr, this message translates to:
  /// **'Profesör'**
  String get professor;

  /// No description provided for @lecturer.
  ///
  /// In tr, this message translates to:
  /// **'Öğretim Görevlisi'**
  String get lecturer;

  /// No description provided for @researcher.
  ///
  /// In tr, this message translates to:
  /// **'Araştırmacı'**
  String get researcher;

  /// No description provided for @scientist.
  ///
  /// In tr, this message translates to:
  /// **'Bilim İnsanı'**
  String get scientist;

  /// No description provided for @engineer.
  ///
  /// In tr, this message translates to:
  /// **'Mühendis'**
  String get engineer;

  /// No description provided for @developer.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get developer;

  /// No description provided for @designer.
  ///
  /// In tr, this message translates to:
  /// **'Tasarımcı'**
  String get designer;

  /// No description provided for @manager.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici'**
  String get manager;

  /// No description provided for @director.
  ///
  /// In tr, this message translates to:
  /// **'Müdür'**
  String get director;

  /// No description provided for @executive.
  ///
  /// In tr, this message translates to:
  /// **'Üst Düzey Yönetici'**
  String get executive;

  /// No description provided for @ceo.
  ///
  /// In tr, this message translates to:
  /// **'CEO'**
  String get ceo;

  /// No description provided for @cto.
  ///
  /// In tr, this message translates to:
  /// **'CTO'**
  String get cto;

  /// No description provided for @cfo.
  ///
  /// In tr, this message translates to:
  /// **'CFO'**
  String get cfo;

  /// No description provided for @coo.
  ///
  /// In tr, this message translates to:
  /// **'COO'**
  String get coo;

  /// No description provided for @cmo.
  ///
  /// In tr, this message translates to:
  /// **'CMO'**
  String get cmo;

  /// No description provided for @chro.
  ///
  /// In tr, this message translates to:
  /// **'CHRO'**
  String get chro;

  /// No description provided for @cio.
  ///
  /// In tr, this message translates to:
  /// **'CIO'**
  String get cio;

  /// No description provided for @ciso.
  ///
  /// In tr, this message translates to:
  /// **'CISO'**
  String get ciso;

  /// No description provided for @vp.
  ///
  /// In tr, this message translates to:
  /// **'Başkan Yardımcısı'**
  String get vp;

  /// No description provided for @head.
  ///
  /// In tr, this message translates to:
  /// **'Departman Başkanı'**
  String get head;

  /// No description provided for @lead.
  ///
  /// In tr, this message translates to:
  /// **'Lider'**
  String get lead;

  /// No description provided for @senior.
  ///
  /// In tr, this message translates to:
  /// **'Kıdemli'**
  String get senior;

  /// No description provided for @junior.
  ///
  /// In tr, this message translates to:
  /// **'Junior'**
  String get junior;

  /// No description provided for @mid.
  ///
  /// In tr, this message translates to:
  /// **'Orta Düzey'**
  String get mid;

  /// No description provided for @entry.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Düzeyi'**
  String get entry;

  /// No description provided for @intern.
  ///
  /// In tr, this message translates to:
  /// **'Stajyer'**
  String get intern;

  /// No description provided for @freelance.
  ///
  /// In tr, this message translates to:
  /// **'Serbest Çalışan'**
  String get freelance;

  /// No description provided for @contract.
  ///
  /// In tr, this message translates to:
  /// **'Sözleşmeli'**
  String get contract;

  /// No description provided for @permanent.
  ///
  /// In tr, this message translates to:
  /// **'Kadrolu'**
  String get permanent;

  /// No description provided for @partTime.
  ///
  /// In tr, this message translates to:
  /// **'Yarı Zamanlı'**
  String get partTime;

  /// No description provided for @fullTime.
  ///
  /// In tr, this message translates to:
  /// **'Tam Zamanlı'**
  String get fullTime;

  /// No description provided for @remote.
  ///
  /// In tr, this message translates to:
  /// **'Uzaktan'**
  String get remote;

  /// No description provided for @hybrid.
  ///
  /// In tr, this message translates to:
  /// **'Hibrit'**
  String get hybrid;

  /// No description provided for @onsite.
  ///
  /// In tr, this message translates to:
  /// **'Ofiste'**
  String get onsite;

  /// No description provided for @travel.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk'**
  String get travel;

  /// No description provided for @relocation.
  ///
  /// In tr, this message translates to:
  /// **'Yer Değiştirme'**
  String get relocation;

  /// No description provided for @visa.
  ///
  /// In tr, this message translates to:
  /// **'Vize'**
  String get visa;

  /// No description provided for @workPermit.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma İzni'**
  String get workPermit;

  /// No description provided for @residencePermit.
  ///
  /// In tr, this message translates to:
  /// **'Oturma İzni'**
  String get residencePermit;

  /// No description provided for @passport.
  ///
  /// In tr, this message translates to:
  /// **'Pasaport'**
  String get passport;

  /// No description provided for @id.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik'**
  String get id;

  /// No description provided for @driverLicense.
  ///
  /// In tr, this message translates to:
  /// **'Ehliyet'**
  String get driverLicense;

  /// No description provided for @birthCertificate.
  ///
  /// In tr, this message translates to:
  /// **'Doğum Belgesi'**
  String get birthCertificate;

  /// No description provided for @marriageCertificate.
  ///
  /// In tr, this message translates to:
  /// **'Evlilik Belgesi'**
  String get marriageCertificate;

  /// No description provided for @divorceCertificate.
  ///
  /// In tr, this message translates to:
  /// **'Boşanma Belgesi'**
  String get divorceCertificate;

  /// No description provided for @deathCertificate.
  ///
  /// In tr, this message translates to:
  /// **'Ölüm Belgesi'**
  String get deathCertificate;

  /// No description provided for @medicalReport.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık Raporu'**
  String get medicalReport;

  /// No description provided for @vaccination.
  ///
  /// In tr, this message translates to:
  /// **'Aşı'**
  String get vaccination;

  /// No description provided for @insurance.
  ///
  /// In tr, this message translates to:
  /// **'Sigorta'**
  String get insurance;

  /// No description provided for @health.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get health;

  /// No description provided for @disease.
  ///
  /// In tr, this message translates to:
  /// **'Hastalık'**
  String get disease;

  /// No description provided for @symptom.
  ///
  /// In tr, this message translates to:
  /// **'Belirti'**
  String get symptom;

  /// No description provided for @diagnosis.
  ///
  /// In tr, this message translates to:
  /// **'Tanı'**
  String get diagnosis;

  /// No description provided for @treatment.
  ///
  /// In tr, this message translates to:
  /// **'Tedavi'**
  String get treatment;

  /// No description provided for @medication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get medication;

  /// No description provided for @prescription.
  ///
  /// In tr, this message translates to:
  /// **'Reçete'**
  String get prescription;

  /// No description provided for @surgery.
  ///
  /// In tr, this message translates to:
  /// **'Ameliyat'**
  String get surgery;

  /// No description provided for @hospital.
  ///
  /// In tr, this message translates to:
  /// **'Hastane'**
  String get hospital;

  /// No description provided for @clinic.
  ///
  /// In tr, this message translates to:
  /// **'Klinik'**
  String get clinic;

  /// No description provided for @pharmacy.
  ///
  /// In tr, this message translates to:
  /// **'Eczane'**
  String get pharmacy;

  /// No description provided for @doctor.
  ///
  /// In tr, this message translates to:
  /// **'Doktor'**
  String get doctor;

  /// No description provided for @nurse.
  ///
  /// In tr, this message translates to:
  /// **'Hemşire'**
  String get nurse;

  /// No description provided for @dentist.
  ///
  /// In tr, this message translates to:
  /// **'Diş Hekimi'**
  String get dentist;

  /// No description provided for @ophthalmologist.
  ///
  /// In tr, this message translates to:
  /// **'Göz Doktoru'**
  String get ophthalmologist;

  /// No description provided for @dermatologist.
  ///
  /// In tr, this message translates to:
  /// **'Cildiye Doktoru'**
  String get dermatologist;

  /// No description provided for @cardiologist.
  ///
  /// In tr, this message translates to:
  /// **'Kardiyolog'**
  String get cardiologist;

  /// No description provided for @neurologist.
  ///
  /// In tr, this message translates to:
  /// **'Nörolog'**
  String get neurologist;

  /// No description provided for @orthopedic.
  ///
  /// In tr, this message translates to:
  /// **'Ortopedi'**
  String get orthopedic;

  /// No description provided for @psychiatrist.
  ///
  /// In tr, this message translates to:
  /// **'Psikiyatrist'**
  String get psychiatrist;

  /// No description provided for @psychologist.
  ///
  /// In tr, this message translates to:
  /// **'Psikolog'**
  String get psychologist;

  /// No description provided for @therapist.
  ///
  /// In tr, this message translates to:
  /// **'Terapist'**
  String get therapist;

  /// No description provided for @counselor.
  ///
  /// In tr, this message translates to:
  /// **'Danesman'**
  String get counselor;

  /// No description provided for @socialWorker.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Hizmet Uzmanı'**
  String get socialWorker;

  /// No description provided for @nutritionist.
  ///
  /// In tr, this message translates to:
  /// **'Diyetisyen'**
  String get nutritionist;

  /// No description provided for @physiotherapist.
  ///
  /// In tr, this message translates to:
  /// **'Fizyoterapist'**
  String get physiotherapist;

  /// No description provided for @chiropractor.
  ///
  /// In tr, this message translates to:
  /// **'Kiropraktör'**
  String get chiropractor;

  /// No description provided for @acupuncturist.
  ///
  /// In tr, this message translates to:
  /// **'Akupunkturcu'**
  String get acupuncturist;

  /// No description provided for @herbalist.
  ///
  /// In tr, this message translates to:
  /// **'Bitkisel Tedavi Uzmanı'**
  String get herbalist;

  /// No description provided for @homeopath.
  ///
  /// In tr, this message translates to:
  /// **'Homeopat'**
  String get homeopath;

  /// No description provided for @naturopath.
  ///
  /// In tr, this message translates to:
  /// **'Doğal Tedavi Uzmanı'**
  String get naturopath;

  /// No description provided for @ayurveda.
  ///
  /// In tr, this message translates to:
  /// **'Aurveda Uzmanı'**
  String get ayurveda;

  /// No description provided for @traditionalMedicine.
  ///
  /// In tr, this message translates to:
  /// **'Geleneksel Tıp'**
  String get traditionalMedicine;

  /// No description provided for @alternativeMedicine.
  ///
  /// In tr, this message translates to:
  /// **'Alternatif Tıp'**
  String get alternativeMedicine;

  /// No description provided for @holistic.
  ///
  /// In tr, this message translates to:
  /// **'Bütüncül'**
  String get holistic;

  /// No description provided for @wellness.
  ///
  /// In tr, this message translates to:
  /// **'Sağlıklı Yaşam'**
  String get wellness;

  /// No description provided for @fitness.
  ///
  /// In tr, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// No description provided for @gym.
  ///
  /// In tr, this message translates to:
  /// **'Spor Salonu'**
  String get gym;

  /// No description provided for @yoga.
  ///
  /// In tr, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @pilates.
  ///
  /// In tr, this message translates to:
  /// **'Pilates'**
  String get pilates;

  /// No description provided for @meditation.
  ///
  /// In tr, this message translates to:
  /// **'Meditasyon'**
  String get meditation;

  /// No description provided for @mindfulness.
  ///
  /// In tr, this message translates to:
  /// **'Farkındalık'**
  String get mindfulness;

  /// No description provided for @relaxation.
  ///
  /// In tr, this message translates to:
  /// **'Rahatlama'**
  String get relaxation;

  /// No description provided for @stress.
  ///
  /// In tr, this message translates to:
  /// **'Stres'**
  String get stress;

  /// No description provided for @anxiety.
  ///
  /// In tr, this message translates to:
  /// **'Kaygı'**
  String get anxiety;

  /// No description provided for @depression.
  ///
  /// In tr, this message translates to:
  /// **'Depresyon'**
  String get depression;

  /// No description provided for @insomnia.
  ///
  /// In tr, this message translates to:
  /// **'Uykusuzluk'**
  String get insomnia;

  /// No description provided for @fatigue.
  ///
  /// In tr, this message translates to:
  /// **'Yorgunluk'**
  String get fatigue;

  /// No description provided for @pain.
  ///
  /// In tr, this message translates to:
  /// **'Ağrı'**
  String get pain;

  /// No description provided for @injury.
  ///
  /// In tr, this message translates to:
  /// **'Yaralanma'**
  String get injury;

  /// No description provided for @accident.
  ///
  /// In tr, this message translates to:
  /// **'Kaza'**
  String get accident;

  /// No description provided for @emergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum'**
  String get emergency;

  /// No description provided for @ambulance.
  ///
  /// In tr, this message translates to:
  /// **'Ambulans'**
  String get ambulance;

  /// No description provided for @fire.
  ///
  /// In tr, this message translates to:
  /// **'Yangın'**
  String get fire;

  /// No description provided for @police.
  ///
  /// In tr, this message translates to:
  /// **'Polis'**
  String get police;

  /// No description provided for @gendarmerie.
  ///
  /// In tr, this message translates to:
  /// **'Jandarma'**
  String get gendarmerie;

  /// No description provided for @coastguard.
  ///
  /// In tr, this message translates to:
  /// **'Sahil Güvenlik'**
  String get coastguard;

  /// No description provided for @military.
  ///
  /// In tr, this message translates to:
  /// **'Askeri'**
  String get military;

  /// No description provided for @civilDefense.
  ///
  /// In tr, this message translates to:
  /// **'Sivil Savunma'**
  String get civilDefense;

  /// No description provided for @disaster.
  ///
  /// In tr, this message translates to:
  /// **'Afet'**
  String get disaster;

  /// No description provided for @earthquake.
  ///
  /// In tr, this message translates to:
  /// **'Deprem'**
  String get earthquake;

  /// No description provided for @flood.
  ///
  /// In tr, this message translates to:
  /// **'Sel'**
  String get flood;

  /// No description provided for @storm.
  ///
  /// In tr, this message translates to:
  /// **'Fırtına'**
  String get storm;

  /// No description provided for @hurricane.
  ///
  /// In tr, this message translates to:
  /// **'Kasırğa'**
  String get hurricane;

  /// No description provided for @tornado.
  ///
  /// In tr, this message translates to:
  /// **'Hortum'**
  String get tornado;

  /// No description provided for @tsunami.
  ///
  /// In tr, this message translates to:
  /// **'Tsunami'**
  String get tsunami;

  /// No description provided for @volcano.
  ///
  /// In tr, this message translates to:
  /// **'Yanardağ'**
  String get volcano;

  /// No description provided for @drought.
  ///
  /// In tr, this message translates to:
  /// **'Kuraklık'**
  String get drought;

  /// No description provided for @famine.
  ///
  /// In tr, this message translates to:
  /// **'Kıtlık'**
  String get famine;

  /// No description provided for @epidemic.
  ///
  /// In tr, this message translates to:
  /// **'Salgın'**
  String get epidemic;

  /// No description provided for @pandemic.
  ///
  /// In tr, this message translates to:
  /// **'Pandemi'**
  String get pandemic;

  /// No description provided for @quarantine.
  ///
  /// In tr, this message translates to:
  /// **'Karantina'**
  String get quarantine;

  /// No description provided for @isolation.
  ///
  /// In tr, this message translates to:
  /// **'İzolasyon'**
  String get isolation;

  /// No description provided for @lockdown.
  ///
  /// In tr, this message translates to:
  /// **'Kapanma'**
  String get lockdown;

  /// No description provided for @curfew.
  ///
  /// In tr, this message translates to:
  /// **'Sokağa Çıkma Yasağı'**
  String get curfew;

  /// No description provided for @martialLaw.
  ///
  /// In tr, this message translates to:
  /// **'Sıkıyönetim'**
  String get martialLaw;

  /// No description provided for @stateOfEmergency.
  ///
  /// In tr, this message translates to:
  /// **'Olağanüstü Hal'**
  String get stateOfEmergency;

  /// No description provided for @war.
  ///
  /// In tr, this message translates to:
  /// **'Savaş'**
  String get war;

  /// No description provided for @peace.
  ///
  /// In tr, this message translates to:
  /// **'Barış'**
  String get peace;

  /// No description provided for @conflict.
  ///
  /// In tr, this message translates to:
  /// **'Çatışma'**
  String get conflict;

  /// No description provided for @ceasefire.
  ///
  /// In tr, this message translates to:
  /// **'Ateşkes'**
  String get ceasefire;

  /// No description provided for @treaty.
  ///
  /// In tr, this message translates to:
  /// **'Antlaşma'**
  String get treaty;

  /// No description provided for @alliance.
  ///
  /// In tr, this message translates to:
  /// **'İttifak'**
  String get alliance;

  /// No description provided for @diplomacy.
  ///
  /// In tr, this message translates to:
  /// **'Diplomasi'**
  String get diplomacy;

  /// No description provided for @embargo.
  ///
  /// In tr, this message translates to:
  /// **'Ambargo'**
  String get embargo;

  /// No description provided for @sanction.
  ///
  /// In tr, this message translates to:
  /// **'Yaptırım'**
  String get sanction;

  /// No description provided for @refugee.
  ///
  /// In tr, this message translates to:
  /// **'Mülteci'**
  String get refugee;

  /// No description provided for @asylum.
  ///
  /// In tr, this message translates to:
  /// **'Sığınma'**
  String get asylum;

  /// No description provided for @immigration.
  ///
  /// In tr, this message translates to:
  /// **'Göç'**
  String get immigration;

  /// No description provided for @emigration.
  ///
  /// In tr, this message translates to:
  /// **'Göç'**
  String get emigration;

  /// No description provided for @citizenship.
  ///
  /// In tr, this message translates to:
  /// **'Vatandaşlık'**
  String get citizenship;

  /// No description provided for @nationality.
  ///
  /// In tr, this message translates to:
  /// **'Uyruk'**
  String get nationality;

  /// No description provided for @ethnicity.
  ///
  /// In tr, this message translates to:
  /// **'Etnisite'**
  String get ethnicity;

  /// No description provided for @race.
  ///
  /// In tr, this message translates to:
  /// **'Irk'**
  String get race;

  /// No description provided for @gender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get gender;

  /// No description provided for @sex.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get sex;

  /// No description provided for @age.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get age;

  /// No description provided for @birth.
  ///
  /// In tr, this message translates to:
  /// **'Doğum'**
  String get birth;

  /// No description provided for @death.
  ///
  /// In tr, this message translates to:
  /// **'Ölüm'**
  String get death;

  /// No description provided for @marriage.
  ///
  /// In tr, this message translates to:
  /// **'Evlilik'**
  String get marriage;

  /// No description provided for @divorce.
  ///
  /// In tr, this message translates to:
  /// **'Boşanma'**
  String get divorce;

  /// No description provided for @widow.
  ///
  /// In tr, this message translates to:
  /// **'Dul'**
  String get widow;

  /// No description provided for @widower.
  ///
  /// In tr, this message translates to:
  /// **'Dul'**
  String get widower;

  /// No description provided for @orphan.
  ///
  /// In tr, this message translates to:
  /// **'Yetim'**
  String get orphan;

  /// No description provided for @family.
  ///
  /// In tr, this message translates to:
  /// **'Aile'**
  String get family;

  /// No description provided for @parent.
  ///
  /// In tr, this message translates to:
  /// **'Ebeveyn'**
  String get parent;

  /// No description provided for @child.
  ///
  /// In tr, this message translates to:
  /// **'Çocuk'**
  String get child;

  /// No description provided for @son.
  ///
  /// In tr, this message translates to:
  /// **'Oğul'**
  String get son;

  /// No description provided for @daughter.
  ///
  /// In tr, this message translates to:
  /// **'Kız Evlat'**
  String get daughter;

  /// No description provided for @brother.
  ///
  /// In tr, this message translates to:
  /// **'Erkek Kardeş'**
  String get brother;

  /// No description provided for @sister.
  ///
  /// In tr, this message translates to:
  /// **'Kız Kardeş'**
  String get sister;

  /// No description provided for @husband.
  ///
  /// In tr, this message translates to:
  /// **'Koca'**
  String get husband;

  /// No description provided for @wife.
  ///
  /// In tr, this message translates to:
  /// **'Karı'**
  String get wife;

  /// No description provided for @father.
  ///
  /// In tr, this message translates to:
  /// **'Baba'**
  String get father;

  /// No description provided for @mother.
  ///
  /// In tr, this message translates to:
  /// **'Anne'**
  String get mother;

  /// No description provided for @grandfather.
  ///
  /// In tr, this message translates to:
  /// **'Büyükbaba'**
  String get grandfather;

  /// No description provided for @grandmother.
  ///
  /// In tr, this message translates to:
  /// **'Büyükanne'**
  String get grandmother;

  /// No description provided for @uncle.
  ///
  /// In tr, this message translates to:
  /// **'Amca'**
  String get uncle;

  /// No description provided for @aunt.
  ///
  /// In tr, this message translates to:
  /// **'Teyze'**
  String get aunt;

  /// No description provided for @cousin.
  ///
  /// In tr, this message translates to:
  /// **'Kuzen'**
  String get cousin;

  /// No description provided for @nephew.
  ///
  /// In tr, this message translates to:
  /// **'Yeğen'**
  String get nephew;

  /// No description provided for @niece.
  ///
  /// In tr, this message translates to:
  /// **'Yeğen'**
  String get niece;

  /// No description provided for @inLaw.
  ///
  /// In tr, this message translates to:
  /// **'Kayın'**
  String get inLaw;

  /// No description provided for @step.
  ///
  /// In tr, this message translates to:
  /// **'Üvey'**
  String get step;

  /// No description provided for @adopted.
  ///
  /// In tr, this message translates to:
  /// **'Evlatlık'**
  String get adopted;

  /// No description provided for @foster.
  ///
  /// In tr, this message translates to:
  /// **'Sütanne'**
  String get foster;

  /// No description provided for @godparent.
  ///
  /// In tr, this message translates to:
  /// **'Vaftiz'**
  String get godparent;

  /// No description provided for @sibling.
  ///
  /// In tr, this message translates to:
  /// **'Kardeş'**
  String get sibling;

  /// No description provided for @twin.
  ///
  /// In tr, this message translates to:
  /// **'İkiz'**
  String get twin;

  /// No description provided for @triplet.
  ///
  /// In tr, this message translates to:
  /// **'Üçüz'**
  String get triplet;

  /// No description provided for @quadruplet.
  ///
  /// In tr, this message translates to:
  /// **'Dördüz'**
  String get quadruplet;

  /// No description provided for @quintuplet.
  ///
  /// In tr, this message translates to:
  /// **'Beşiz'**
  String get quintuplet;

  /// No description provided for @sextuplet.
  ///
  /// In tr, this message translates to:
  /// **'Altız'**
  String get sextuplet;

  /// No description provided for @septuplet.
  ///
  /// In tr, this message translates to:
  /// **'Yediz'**
  String get septuplet;

  /// No description provided for @octuplet.
  ///
  /// In tr, this message translates to:
  /// **'Sekiziz'**
  String get octuplet;

  /// No description provided for @nonuplet.
  ///
  /// In tr, this message translates to:
  /// **'Dokuziz'**
  String get nonuplet;

  /// No description provided for @decuplet.
  ///
  /// In tr, this message translates to:
  /// **'Onuz'**
  String get decuplet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
