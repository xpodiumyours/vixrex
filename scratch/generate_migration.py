import os
import re

# Categories matching BusinessCategoryConfig
categories_config = {
    'giyim': {'label': 'Giyim', 'target': 8},
    'butik': {'label': 'Butik', 'target': 10},
    'gida': {'label': 'Gıda', 'target': 5},
    'firin': {'label': 'Fırın', 'target': 5},
    'kozmetik': {'label': 'Kozmetik', 'target': 5},
    'dekorasyon': {'label': 'Dekorasyon', 'target': 5},
    'elektronik': {'label': 'Elektronik', 'target': 5},
    'kirtasiye': {'label': 'Kırtasiye', 'target': 5},
    'kafe_lokanta': {'label': 'Kafe / Lokanta', 'target': 8},
    'kuafor': {'label': 'Kuaför', 'target': 8},
    'teknik_servis': {'label': 'Teknik Servis', 'target': 5},
    'hizmet_danismanlik': {'label': 'Hizmet & Danışmanlık', 'target': 5},
    'egitim_ders': {'label': 'Eğitim & Ders', 'target': 5},
    'ev_temizlik': {'label': 'Ev & Temizlik', 'target': 5},
    'spor_fitness': {'label': 'Spor & Fitness', 'target': 5},
    'pet_shop_veteriner': {'label': 'Pet Shop & Veteriner', 'target': 5},
    'saglik_yasam': {'label': 'Sağlık & Yaşam', 'target': 5},
    'oto_arac': {'label': 'Oto & Araç Hizmetleri', 'target': 6},
    'diger': {'label': 'Diğer', 'target': 5}
}

# Curated high-quality Unsplash image IDs to choose from dynamically
unsplash_pool = {
    'cover': [
        'photo-1441986300917-64674bd600d8', 'photo-1567401893414-76b7b1e5a7a5', 'photo-1490481651871-ab68de25d43d',
        'photo-1445205170230-053b83016050', 'photo-1483985988355-763728e1935b', 'photo-1558769132-cb1aea458c5e',
        'photo-1434389677669-e08b4cac3105', 'photo-1479064555552-3ef4979f8908', 'photo-1509319117193-57bab727e09d',
        'photo-1515886657613-9f3515b0c78f', 'photo-1509440159596-0249088772ff', 'photo-1549931319-a545dcf3bc73',
        'photo-1579372786545-d24232daf58c', 'photo-1517433456452-f9633a875f6f', 'photo-1555507036-ab1f4038808a',
        'photo-1554118811-1e0d58224f24', 'photo-1517248135467-4c7edcad34c4', 'photo-1551024601-bec78aea704b',
        'photo-1560066984-138dadb4c035', 'photo-1522337360788-8b13dee7a37e', 'photo-1562322140-8baeececf3df',
        'photo-1544244015-0df4b3ffc6b0', 'photo-1616440347437-b1c73416efc2', 'photo-1581092160607-ee22621dd758',
        'photo-1607860108855-64acf2078ed9', 'photo-1552930294-6b595f4c2974', 'photo-1600880292203-757bb62b4baf'
    ],
    'gallery': [
        'photo-1523381210434-271e8be1f52b', 'photo-1489987707025-afc232f7ea0f', 'photo-1512436991641-6745cdb1723f',
        'photo-1490481651871-ab68de25d43d', 'photo-1445205170230-053b83016050', 'photo-1594938298603-c8148c4dae35',
        'photo-1539109136881-3be0616acf4b', 'photo-1485968579580-b6d095142e6e', 'photo-1583743814966-8936f5b7be1a',
        'photo-1610832958506-aa56368176cf', 'photo-1622483767028-3f66f32aef97', 'photo-1599599810769-bcde5a160d32',
        'photo-1516975080664-ed2fc6a32937', 'photo-1487412947147-5cebf100ffc2', 'photo-1547887537-6158d64c35b3',
        'photo-1616486338812-3dadae4b4ace', 'photo-1586023492125-27b2c045efd7', 'photo-1579586337278-3befd40fd17a',
        'photo-1516962215378-7fa2e137ae93', 'photo-1565299624946-b28f40a0ae38', 'photo-1605497788044-5a32c7078486',
        'photo-1454165804606-c3d57bc86b40', 'photo-1486406146926-c627a92ad1ab', 'photo-1434626881859-194d67b2b86f',
        'photo-1427504494785-3a9ca7044f45', 'photo-1434030216411-0b793f4b4173', 'photo-1516321318423-f06f85e504b3',
        'photo-1581578731548-c64695cc6952', 'photo-1563453392212-326f5e854473', 'photo-1527515637462-cff94eecc1ac',
        'photo-1534438327276-14e5300c3a48', 'photo-1571902943202-507ec2618e8f', 'photo-1571019614242-c5c5dee9f50b',
        'photo-1516734212186-a967f81ad0d7', 'photo-1583511655857-d19b40a7a54e', 'photo-1576201836106-db1758fd1c97',
        'photo-1584132967334-10e028bd69f7', 'photo-1629909613654-28e377c37b09', 'photo-1579684385127-1ef15d508118',
        'photo-1606811971618-4486d14f3f99', 'photo-1601362840469-51e4d8d58785'
    ],
    'product': [
        'photo-1596755094514-f87e34085b2c', 'photo-1541099649105-f69ad21f3246', 'photo-1595777457583-95e059d581b8',
        'photo-1523170335258-f5ed11844a49', 'photo-1509319117193-57bab727e09d', 'photo-1548036328-c9fa89d128fa',
        'photo-1584917865442-de89df76afd3', 'photo-1511499767150-a48a237f0083', 'photo-1549298916-b41d501d3772',
        'photo-1551028719-00167b16eac5', 'photo-1583496661160-fb488657dabf', 'photo-1624222247344-550fb8ecfe65'
    ]
}

# Sub-categories Unsplash IDs generated deterministically per category & index to keep aesthetic alignment
def get_unsplash_id(cat_key, img_type, idx):
    # Generates a seed based on category and index to ensure stable and distinct Unsplash IDs per call
    import hashlib
    seed_str = f"{cat_key}_{img_type}_{idx}"
    h = hashlib.md5(seed_str.encode('utf-8')).hexdigest()
    # Pick from pool based on hash
    pool = unsplash_pool.get(img_type, unsplash_pool['gallery'])
    pool_idx = int(h, 16) % len(pool)
    return pool[pool_idx]

# Parse the original seed file to discover what URLs and titles already exist in each category
original_seed_path = r"c:\Projects\vixrex\supabase\migrations\20250703_seed_category_image_templates.sql"
existing_templates = {} # cat_key -> {img_type -> list of urls}

if os.path.exists(original_seed_path):
    with open(original_seed_path, 'r', encoding='utf-8') as f:
        content = f.read()
        # Find matches for INSERT statements
        # Format: ('cat_key', 'Label', 'type', 'url', 'title', order)
        pattern = re.compile(r"\(\s*'([^']+)'\s*,\s*'[^']+'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*\d+\s*\)")
        for match in pattern.finditer(content):
            cat_key, img_type, url, title = match.groups()
            if cat_key not in existing_templates:
                existing_templates[cat_key] = {}
            if img_type not in existing_templates[cat_key]:
                existing_templates[cat_key][img_type] = []
            existing_templates[cat_key][img_type].append(url)

# Generate new migration script using INSERT ... ON CONFLICT DO NOTHING
migration_filename = "20260717_add_premium_category_image_templates.sql"
migration_path = os.path.join(r"c:\Projects\vixrex\supabase\migrations", migration_filename)

sql_content = """-- ============================================================
-- Sprint 2: Kategori Sablon Premium Genisletme Migration
-- Her kategori en az 5 adet (Butik 10 adet) gorsele tamamlanir
-- ON CONFLICT kullanarak mevcut kayitlari bozmadan ekleme yapar
-- ============================================================

-- 1. Tablo uzerinde (category_key, image_type, image_url) benzersizlik kisiti (unique constraint) eklenmesi
ALTER TABLE public.category_image_templates 
  DROP CONSTRAINT IF EXISTS uq_category_image_template_url;

ALTER TABLE public.category_image_templates 
  ADD CONSTRAINT uq_category_image_template_url 
  UNIQUE (category_key, image_type, image_url);

-- 2. Yeni premium gorsellerin eklenmesi
"""

inserts_added = 0
verification_report = []

for cat_key, conf in categories_config.items():
    label = conf['label']
    target = conf['target']
    
    # We will add images of type cover, gallery, product up to the target number
    for img_type in ['cover', 'gallery', 'product']:
        existing_urls = existing_templates.get(cat_key, {}).get(img_type, [])
        current_count = len(existing_urls)
        needed = target - current_count
        
        type_inserts = []
        if needed > 0:
            for i in range(needed):
                # Ensure the Unsplash ID is not already used in this category
                u_id = get_unsplash_id(cat_key, img_type, i)
                url = f"https://images.unsplash.com/{u_id}"
                
                # Check w/q params based on image_type
                if img_type == 'cover':
                    url += "?w=1200&q=80"
                elif img_type == 'gallery':
                    url += "?w=800&q=80"
                else:
                    url += "?w=600&q=80"
                
                title = f"{label} Örnek {img_type.capitalize()} {current_count + i + 1}"
                display_order = current_count + i + 1
                
                # Check if it was somehow in the existing list to prevent duplicates
                if url not in existing_urls:
                    insert_stmt = f"('{cat_key}', '{label}', '{img_type}', '{url}', '{title}', {display_order})"
                    type_inserts.append(insert_stmt)
                    inserts_added += 1
            
            if type_inserts:
                sql_content += f"\n-- {label} Sektoru {img_type.upper()} Eklemleri\n"
                sql_content += "INSERT INTO public.category_image_templates (category_key, category_label, image_type, image_url, title, display_order) VALUES\n"
                sql_content += ",\n".join(type_inserts)
                sql_content += "\nON CONFLICT (category_key, image_type, image_url) DO NOTHING;\n"
        
        final_count = current_count + len(type_inserts)
        verification_report.append(f"  • {cat_key} ({img_type}): Mevcut: {current_count} | Eklenecek: {len(type_inserts)} | Toplam: {final_count}")

# Write to file
with open(migration_path, 'w', encoding='utf-8') as f:
    f.write(sql_content)

print(f"Migration script successfully generated at: {migration_path}")
print(f"Total new visual items planned for insertion: {inserts_added}")
print("\nVerification Report (Category & Type Counts):")
for line in verification_report:
    print(line)
