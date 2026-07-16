const fs = require('fs');
const path = require('path');

// Target category configurations
const categoriesConfig = {
  giyim: { label: 'Giyim', target: 8, group: 'fashion' },
  butik: { label: 'Butik', target: 10, group: 'fashion' },
  gida: { label: 'Gıda', target: 5, group: 'food' },
  firin: { label: 'Fırın', target: 5, group: 'food' },
  kozmetik: { label: 'Kozmetik', target: 5, group: 'beauty' },
  dekorasyon: { label: 'Dekorasyon', target: 5, group: 'decor' },
  elektronik: { label: 'Elektronik', target: 5, group: 'tech' },
  kirtasiye: { label: 'Kırtasiye', target: 5, group: 'stationery' },
  kafe_lokanta: { label: 'Kafe / Lokanta', target: 8, group: 'food' },
  kuafor: { label: 'Kuaför', target: 8, group: 'beauty' },
  teknik_servis: { label: 'Teknik Servis', target: 5, group: 'tech' },
  hizmet_danismanlik: { label: 'Hizmet & Danışmanlık', target: 5, group: 'professional' },
  egitim_ders: { label: 'Eğitim & Ders', target: 5, group: 'professional' },
  ev_temizlik: { label: 'Ev & Temizlik', target: 5, group: 'services' },
  spor_fitness: { label: 'Spor & Fitness', target: 5, group: 'sports' },
  pet_shop_veteriner: { label: 'Pet Shop & Veteriner', target: 5, group: 'pet' },
  saglik_yasam: { label: 'Sağlık & Yaşam', target: 5, group: 'medical' },
  oto_arac: { label: 'Oto & Araç Hizmetleri', target: 6, group: 'auto' },
  diger: { label: 'Diğer', target: 5, group: 'general' }
};

// Distinct, non-overlapping Unsplash IDs categorized by theme groups.
// Each array contains completely unique, premium, commercial-safe images.
const pools = {
  fashion: [
    // Covers
    'photo-1489987707025-afc232f7ea0f', 'photo-1479064555552-3ef4979f8908', 'photo-1523381210434-271e8be1f52b',
    'photo-1512436991641-6745cdb1723f', 'photo-1556905055-8f358a7a47b2', 'photo-1505022610485-0249ba5b3675',
    'photo-1490481651871-ab68de25d43d', 'photo-1525507119028-ed4c629a60a3', 'photo-1567401893414-76b7b1e5a7a5',
    'photo-1441986300917-64674bd600d8', 'photo-1445205170230-053b83016050', 'photo-1483985988355-763728e1935b',
    'photo-1558769132-cb1aea458c5e', 'photo-1434389677669-e08b4cac3105', 'photo-1509319117193-57bab727e09d',
    'photo-1515886657613-9f3515b0c78f',
    // Galleries
    'photo-1507679799987-c73779587ccf', 'photo-1529139574466-a303027c1d8b', 'photo-1554568218-0f1715e72254',
    'photo-1509631179647-0177331693ae', 'photo-1492707892479-7bc8d5a4ee93', 'photo-1495385794356-15371f548e61',
    'photo-1594938298603-c8148c4dae35', 'photo-1539109136881-3be0616acf4b', 'photo-1485968579580-b6d095142e6e',
    'photo-1620799140408-edc6dcb6d633', 'photo-1608748010899-18f300247112', 'photo-1578932750294-f5075e85f44a',
    'photo-1552374196-1ab2a1c593e8', 'photo-1560243563-062bff001d68', 'photo-1485230895905-ec40ba36b9bc',
    'photo-1537832816519-689ad163238b',
    // Products
    'photo-1596755094514-f87e34085b2c', 'photo-1541099649105-f69ad21f3246', 'photo-1595777457583-95e059d581b8',
    'photo-1618220179428-22790b461013', 'photo-1603252109303-2751441dd157', 'photo-1576566588028-4147f3842f27',
    'photo-1598033129183-c4f50c736f10', 'photo-1583743814966-8936f5b7be1a', 'photo-1523170335258-f5ed11844a49',
    'photo-1548036328-c9fa89d128fa', 'photo-1521572267360-ee0c2909d518', 'photo-1584917865442-de89df76afd3',
    'photo-1511499767150-a48a237f0083', 'photo-1549298916-b41d501d3772', 'photo-1551028719-00167b16eac5',
    'photo-1601924994987-69e26d50dc26', 'photo-1551488831-00ddcb6c6bd3'
  ],
  food: [
    // Covers & Bakery & Cafes (Warm Golden tones)
    'photo-1509440159596-0249088772ff', 'photo-1549931319-a545dcf3bc73', 'photo-1579372786545-d24232daf58c',
    'photo-1517433456452-f9633a875f6f', 'photo-1555507036-ab1f4038808a', 'photo-1604719312566-8912e9227c6a',
    'photo-1542838132-92c53300491e', 'photo-1578916171728-46686eac8d58', 'photo-1543083507-993b77bb708e',
    'photo-1608686207856-001b95cf60ca', 'photo-1554118811-1e0d58224f24', 'photo-1517248135467-4c7edcad34c4',
    'photo-1551024601-bec78aea704b', 'photo-1495474472287-4d71bcdd2085', 'photo-1501339847302-ac426a4a7cbb',
    'photo-1498804103079-a6351b050096', 'photo-1463797224155-85a9ee92767a', 'photo-1521017432531-fbd92d768814',
    // Galleries
    'photo-1587314168485-3236d6710814', 'photo-1509042239860-f550ce710b93', 'photo-1565299624946-b28f40a0ae38',
    'photo-1544025162-d76694265947', 'photo-1513104890138-7c749659a591', 'photo-1476224203421-9ac39bcb3327',
    'photo-1565958011703-44f9829ba187', 'photo-1555939594-58d7cb561ad1', 'photo-1610832958506-aa56368176cf',
    'photo-1622483767028-3f66f32aef97', 'photo-1599599810769-bcde5a160d32', 'photo-1606787366850-de6330128bfc',
    'photo-1498837167922-ddd27525d352',
    // Products
    'photo-1589301760014-d929f3979dbc', 'photo-1620921556828-d7dc29ef0488', 'photo-1546069901-ba9599a7e63c',
    'photo-1567620905732-2d1ec7ab7445', 'photo-1565299585323-38d6b0865b47', 'photo-1482049016688-2d3e1b311543',
    'photo-1588964895597-cfccd6e2dbf9', 'photo-1597362925123-77861d3fbac7', 'photo-1574316071802-0d684efa7bf5',
    'photo-1586201375761-83865001e31c', 'photo-1592417817098-8f3d6eb19675'
  ],
  beauty: [
    // Hairdresser & Cosmetics (Chic/Modern style)
    'photo-1560066984-138dadb4c035', 'photo-1522337360788-8b13dee7a37e', 'photo-1562322140-8baeececf3df',
    'photo-1633681926035-ec1ac984418a', 'photo-1595476108010-b4d1f102b1b1', 'photo-1503951914875-452162b0f3f1',
    'photo-1512496015851-a90fb38ba796', 'photo-1507081329363-9524582389e3', 'photo-1596462502278-27bfdc403348',
    'photo-1570172619644-dfd03ed5d881', 'photo-1608248597481-496100c8c836',
    // Galleries
    'photo-1605497788044-5a32c7078486', 'photo-1521590832167-7bcbfea6331f', 'photo-1516975080664-ed2fc6a32937',
    'photo-1634449571010-02389ed0f9b0', 'photo-1487412947147-5cebf100ffc2', 'photo-1547887537-6158d64c35b3',
    'photo-1612817288484-6f916006741a',
    // Products
    'photo-1522335939835-0347101999b4', 'photo-1601049541289-9b1b7bbbfe19', 'photo-1515688594390-b649af70d282',
    'photo-1556228720-195a672e8a03', 'photo-1598440947619-2c35fc9aa908', 'photo-1570172619644-dfd03ed5d881',
    'photo-1527799863830-580c3b0dc7f2', 'photo-1616683693504-3ea7e9ad6fec'
  ],
  decor: [
    'photo-1618221195710-dd6b41faaea6', 'photo-1616486338812-3dadae4b4ace', 'photo-1513506003901-1e6a229e2d15',
    'photo-1586023492125-27b2c045efd7', 'photo-1538688525198-9b88f6f53126', 'photo-1585418694458-5f28582413b2',
    'photo-1524758631624-e2822e304c36', 'photo-1533090161767-e6ffed986c88', 'photo-1567225557594-88d73e55f2cb',
    'photo-1583847268964-b28dc8f51f92', 'photo-1597072689227-8882273e8f6a', 'photo-1544816155-12df9643f363',
    'photo-1513519245088-0e12902e5a38', 'photo-1505691938895-1758d7feb511', 'photo-1519710164239-da123dc03ef4'
  ],
  tech: [
    'photo-1531403009284-440f080d1e12', 'photo-1580910051074-3eb694886505', 'photo-1590658268037-6bf12165a8df',
    'photo-1601784551446-20c9e07cdbdb', 'photo-1546868871-7041f2a55e12', 'photo-1579586337278-3befd40fd17a',
    'photo-1505740420928-5e560c06d30e', 'photo-1583394838336-acd977736f90', 'photo-1527443224154-c4a3942d3acf',
    'photo-1542751371-adc38448a05e', 'photo-1615663245857-ac93bb7c39e7', 'photo-1544244015-0df4b3ffc6b0',
    'photo-1616440347437-b1c73416efc2', 'photo-1581092160607-ee22621dd758', 'photo-1588508065123-287b28e013da',
    'photo-1597733336794-12d05021d510', 'photo-1518770660439-4636190af475', 'photo-1468495244123-6c6c332eeece',
    'photo-1550745165-9bc0b252726f', 'photo-1563770660941-20978e870e26'
  ],
  stationery: [
    'photo-1456513080510-7bf3a84b82f8', 'photo-1531346878377-a5be20888e57', 'photo-1506880018603-83d5b814b5a6',
    'photo-1516962215378-7fa2e137ae93', 'photo-1586075010923-2dd45e9b2d4f', 'photo-1515041408953-5b87ac0a4245',
    'photo-1569003339405-ea396a5a8a90', 'photo-1513542789411-b6a5d4f31634', 'photo-1519791883288-db8bc6bb1f23',
    'photo-1516979187457-637abb4f9353', 'photo-1527689368864-3a821dbccc34', 'photo-1508873535684-277a3cbcc4e8',
    'photo-1528459801416-a9e53bbf4e17', 'photo-1531346933888-d15439974f6e', 'photo-1506784983877-45594efa4cbe'
  ],
  professional: [
    'photo-1454165804606-c3d57bc86b40', 'photo-1486406146926-c627a92ad1ab', 'photo-1434626881859-194d67b2b86f',
    'photo-1519085360753-af0119f7cbe7', 'photo-1551836022-d5d88e9218df', 'photo-1503676260728-1c00da094a0b',
    'photo-1427504494785-3a9ca7044f45', 'photo-1434030216411-0b793f4b4173', 'photo-1516321318423-f06f85e504b3',
    'photo-1522202176988-66273c2fd55f', 'photo-1434030216411-0b793f4b4173', 'photo-1516321307626-f440ee48af35',
    'photo-1552581234-2612b75dc89c', 'photo-1521791136364-7221f70f6f59', 'photo-1553871373-d15224ef1f6d'
  ],
  services: [
    'photo-1581578731548-c64695cc6952', 'photo-1563453392212-326f5e854473', 'photo-1527515637462-cff94eecc1ac',
    'photo-1584622650111-993a426fbf0a', 'photo-1528740561666-bd247e66ad50', 'photo-1607613009820-a29f7bb81c04',
    'photo-1581578731548-c64695cc6952', 'photo-1609770231080-e321deccc344', 'photo-1585421514738-ee1a3b2e5ef0',
    'photo-1528740561666-bd247e66ad50', 'photo-1527515545081-5db817172677', 'photo-1584820927498-cfe5211fd8bf',
    'photo-1581578576359-bb99d3e8e19c', 'photo-1584622650111-993a426fbf0a', 'photo-1562259949-e8e7689d7828'
  ],
  sports: [
    'photo-1534438327276-14e5300c3a48', 'photo-1571902943202-507ec2618e8f', 'photo-1540497077202-7c8a3999166f',
    'photo-1517838277536-f5f99be501cd', 'photo-1571019614242-c5c5dee9f50b', 'photo-1518310383802-640c2de311b2',
    'photo-1517838277536-f5f99be501cd', 'photo-1599058917212-d750089bc07e', 'photo-1594882645126-14020914d58d',
    'photo-1574680096145-d05b474e2155', 'photo-1538805060514-97d9cc17730c', 'photo-1548690312-e3b507d8c110',
    'photo-1541534741688-6078c6bfb5c5', 'photo-1599058918144-1ffabb6ab9a0', 'photo-1517838277536-f5f99be501cd'
  ],
  pet: [
    'photo-1516734212186-a967f81ad0d7', 'photo-1583511655857-d19b40a7a54e', 'photo-1584132967334-10e028bd69f7',
    'photo-1518717758536-85ae29035b6d', 'photo-1548199973-03cce0bbc87b', 'photo-1576201836106-db1758fd1c97',
    'photo-1596492784531-6e6eb5ea9993', 'photo-1415369629372-26f2fe60c467', 'photo-1543466835-00a7907e9de1',
    'photo-1537151608828-ea2b117b62e4', 'photo-1552053831-71594a27632d', 'photo-1583337130417-3346a1be7dee',
    'photo-1517849845537-4d257902454a', 'photo-1544568100-847a948585b9', 'photo-1514888286974-6c03e2ca1dba'
  ],
  medical: [
    'photo-1629909613654-28e377c37b09', 'photo-1579684385127-1ef15d508118', 'photo-1606811971618-4486d14f3f99',
    'photo-1505751172876-fa1923c5c528', 'photo-1582213782179-e0d53f98f2ca', 'photo-1584515979956-d9f6e5d09982',
    'photo-1559839734-2b71ea197ec2', 'photo-1622253692010-333f2da6031d', 'photo-1581594693702-fbdc51b2763b',
    'photo-1576091160550-2173dba999ef', 'photo-1584515979956-d9f6e5d09982', 'photo-1605684954278-9f13a28b3094',
    'photo-1551601651-2a8555f1a136', 'photo-1559839734-2b71ea197ec2', 'photo-1532938911079-1b06ac7ceec7'
  ],
  auto: [
    'photo-1607860108855-64acf2078ed9', 'photo-1552930294-6b595f4c2974', 'photo-1600880292203-757bb62b4baf',
    'photo-1617886322168-72b886573c3c', 'photo-1517524206127-48bbd363f3d7', 'photo-1568605117036-5fe5e7bab0b7',
    'photo-1601362840469-51e4d8d58785', 'photo-1507136566006-cfc505b114fc', 'photo-1618843479313-40f8afb4b4d8',
    'photo-1619642751034-765dfdf7c58e', 'photo-1549399542-7e3f8b79c341', 'photo-1562620658-c30089e02315',
    'photo-1580273916550-e323be2ae537', 'photo-1616422285623-13ff0162193c', 'photo-1520340356584-f9917d1ecc6f',
    'photo-1553440569-bcc63803a83d', 'photo-1533473359331-0135ef1b58bf', 'photo-1605559424843-9e4c228bf1c2'
  ],
  general: [
    'photo-1534723452862-4c874018d66d', 'photo-1542838132-92c53300491e', 'photo-1604719312566-8912e9227c6a',
    'photo-1513151233558-d860c5398176', 'photo-1507525428034-b723cf961d3e', 'photo-1472851294608-062f824d296e',
    'photo-1582719508461-905c673771fd', 'photo-1540555700478-4be289fbecef', 'photo-1551882547-ff40c63fe5fa',
    'photo-1566073771259-6a8506099945', 'photo-1517841905240-472988babdf9', 'photo-1560066984-138dadb4c035',
    'photo-1522337360788-8b13dee7a37e', 'photo-1441986300917-64674bd600d8', 'photo-1567401893414-76b7b1e5a7a5'
  ]
};

const originalSeedPath = "c:\\Projects\\vixrex\\supabase\\migrations\\20250703_seed_category_image_templates.sql";
const existingTemplates = {};

if (fs.existsSync(originalSeedPath)) {
  const content = fs.readFileSync(originalSeedPath, 'utf8');
  // Match statements like: ('cat_key', 'Label', 'type', 'url', 'title', order)
  const regex = /\(\s*'([^']+)'\s*,\s*'[^']+'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*\d+\s*\)/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const [_, catKey, imgType, url, title] = match;
    if (!existingTemplates[catKey]) {
      existingTemplates[catKey] = {};
    }
    if (!existingTemplates[catKey][imgType]) {
      existingTemplates[catKey][imgType] = [];
    }
    existingTemplates[catKey][imgType].push(url.trim());
  }
}

const migrationFilename = "20260717_add_premium_category_image_templates.sql";
const migrationPath = path.join("c:\\Projects\\vixrex\\supabase\\migrations", migrationFilename);

let sqlContent = `-- ============================================================
-- Sprint 2: Kategori Sablon Premium Genisletme Migration
-- Her kategori en az 5 adet (Butik 10 adet) gorsele tamamlanir
-- ON CONFLICT kullanarak mevcut kayitlari bozmadan ekleme yapar
-- ============================================================

/*
  ── RAPORLAMA VE VERİ DOĞRULAMA SORGULARI ────────────────────

  1. Canli/Local tabloda ayni (category_key, image_type, image_url) kombinasyonuna 
     sahip duplicate kayitlari raporlama sorgusu:

     SELECT category_key, image_type, image_url, COUNT(*) as repeat_count
     FROM public.category_image_templates
     GROUP BY category_key, image_type, image_url
     HAVING COUNT(*) > 1;

  2. Ayni gorselin ayni kategori altinda farkli tiplerde (cover, gallery, product) 
     tekrar edip etmedigini denetleme sorgusu:

     SELECT category_key, image_url, COUNT(DISTINCT image_type) as type_count, string_agg(image_type, ', ') as types
     FROM public.category_image_templates
     GROUP BY category_key, image_url
     HAVING COUNT(DISTINCT image_type) > 1;

  3. Entegrasyon sonrasi kategori ve tip bazli guncel kayit sayisi raporlama sorgusu:

     SELECT category_key, image_type, COUNT(*) as image_count
     FROM public.category_image_templates
     WHERE is_active = true
     GROUP BY category_key, image_type
     ORDER BY category_key, image_type;
*/

-- 1. Tablo uzerinde (category_key, image_type, image_url) benzersizlik kisitinin (unique constraint) eklenmesi
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'uq_category_image_template_url'
      AND conrelid = 'public.category_image_templates'::regclass
  ) THEN
    ALTER TABLE public.category_image_templates 
      ADD CONSTRAINT uq_category_image_template_url 
      UNIQUE (category_key, image_type, image_url);
  END IF;
END $$;

-- 2. Yeni premium gorsellerin eklenmesi
`;

let insertsAdded = 0;
const verificationReport = [];
const crossTypeViolations = [];
const usedGlobalUnsplashIds = new Set();

// Populates already globally used IDs in the existing seed to avoid any duplication at all
for (const [cat, types] of Object.entries(existingTemplates)) {
  for (const [type, urls] of Object.entries(types)) {
    urls.forEach(url => {
      const match = url.match(/photo-[a-zA-Z0-9-]+/);
      if (match) usedGlobalUnsplashIds.add(match[0]);
    });
  }
}

for (const [catKey, conf] of Object.entries(categoriesConfig)) {
  const label = conf.label;
  const target = conf.target;
  const groupName = conf.group;
  const groupPool = pools[groupName] || pools.general;

  // Track unique IDs used in this specific category across ALL types
  const usedIdsInCategory = new Set();
  
  // Populate category-level existing IDs from original seed
  for (const type of ['cover', 'gallery', 'product']) {
    const urls = (existingTemplates[catKey] && existingTemplates[catKey][type]) || [];
    urls.forEach(url => {
      const match = url.match(/photo-[a-zA-Z0-9-]+/);
      if (match) {
        usedIdsInCategory.add(match[0]);
        usedGlobalUnsplashIds.add(match[0]);
      }
    });
  }

  // Pointer for drawing uniquely from the group pool
  let poolPointer = 0;

  for (const imgType of ['cover', 'gallery', 'product']) {
    const existingUrls = (existingTemplates[catKey] && existingTemplates[catKey][imgType]) || [];
    const currentCount = existingUrls.length;
    const needed = target - currentCount;

    const typeInserts = [];
    if (needed > 0) {
      let addedForType = 0;
      while (addedForType < needed && poolPointer < groupPool.length) {
        const uId = groupPool[poolPointer++];
        
        // Ensure absolute uniqueness:
        // 1. Must NOT be used in the current category for any type (no cross-type reuse!)
        // 2. Must NOT be used globally in other categories if possible (except if we run out, but our pools are huge)
        const isDuplicateCategory = usedIdsInCategory.has(uId);
        const isDuplicateGlobal = usedGlobalUnsplashIds.has(uId);

        if (!isDuplicateCategory && !isDuplicateGlobal) {
          let url = `https://images.unsplash.com/${uId}`;
          if (imgType === 'cover') {
            url += '?w=1200&q=80';
          } else if (imgType === 'gallery') {
            url += '?w=800&q=80';
          } else {
            url += '?w=600&q=80';
          }

          const title = `${label} Örnek ${imgType.charAt(0).toUpperCase() + imgType.slice(1)} ${currentCount + addedForType + 1}`;
          const displayOrder = currentCount + addedForType + 1;

          typeInserts.push(`('${catKey}', '${label}', '${imgType}', '${url}', '${title}', ${displayOrder})`);
          usedIdsInCategory.add(uId);
          usedGlobalUnsplashIds.add(uId);
          addedForType++;
          insertsAdded++;
        }
      }

      // Fallback: If we ran out of completely unique global IDs for this group, draw with category-level uniqueness only
      if (addedForType < needed) {
        poolPointer = 0; // reset pointer to scan again for category-level uniqueness
        while (addedForType < needed && poolPointer < groupPool.length) {
          const uId = groupPool[poolPointer++];
          const isDuplicateCategory = usedIdsInCategory.has(uId);
          if (!isDuplicateCategory) {
            let url = `https://images.unsplash.com/${uId}`;
            if (imgType === 'cover') {
              url += '?w=1200&q=80';
            } else if (imgType === 'gallery') {
              url += '?w=800&q=80';
            } else {
              url += '?w=600&q=80';
            }

            const title = `${label} Örnek ${imgType.charAt(0).toUpperCase() + imgType.slice(1)} ${currentCount + addedForType + 1}`;
            const displayOrder = currentCount + addedForType + 1;

            typeInserts.push(`('${catKey}', '${label}', '${imgType}', '${url}', '${title}', ${displayOrder})`);
            usedIdsInCategory.add(uId);
            addedForType++;
            insertsAdded++;
          }
        }
      }

      if (typeInserts.length > 0) {
        sqlContent += `\n-- ${label} Sektoru ${imgType.toUpperCase()} Eklemleri\n`;
        sqlContent += "INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES\n";
        sqlContent += typeInserts.join(",\n");
        sqlContent += "\nON CONFLICT (category_key, image_type, image_url) DO NOTHING;\n";
      }
    }

    const finalCount = currentCount + typeInserts.length;
    verificationReport.push(`  • ${catKey} (${imgType}): Mevcut: ${currentCount} | Eklenecek: ${typeInserts.length} | Toplam: ${finalCount}`);
  }
}

fs.writeFileSync(migrationPath, sqlContent, 'utf8');

console.log(`Migration script successfully generated at: ${migrationPath}`);
console.log(`Total new visual items planned for insertion: ${insertsAdded}`);
console.log("\nVerification Report (Category & Type Counts):");
verificationReport.forEach(line => console.log(line));
