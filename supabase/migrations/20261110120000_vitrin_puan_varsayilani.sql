begin;

alter table public.stores alter column rating_score drop default;
alter table public.stores alter column review_count drop default;

update public.stores
   set rating_score = null,
       review_count = null,
       show_storefront_rating = false
 where rating_score = 4.9
   and review_count = 128
   and is_demo is not true;

commit;
